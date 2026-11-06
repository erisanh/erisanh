#!/usr/bin/env python3
"""warp-doh-proxy — loopback HTTP CONNECT proxy in front of Cloudflare WARP's SOCKS5 (proxy mode).

Why it exists
-------------
Some ISPs (Vietnam) block sites twice: the system DNS answers a sinkhole address AND the TLS
handshake is reset on the SNI. A VPN/WARP fixes the second, but WARP in `proxy` mode resolves
hostnames with the *system* resolver, so a name-based SOCKS request for a blocked site is refused
(curl: "SOCKS5 ... (5)", Chromium: ERR_SOCKS_CONNECTION_FAILED) — Chromium's --host-resolver-rules
does not help, because it still hands the NAME to the proxy.

This proxy takes `CONNECT host:port`, resolves `host` itself over DoH (1.1.1.1), and asks WARP's
SOCKS5 to connect to the resulting IP. Clients (Brave, Playwright, curl_cffi, yt-dlp) only see an
ordinary HTTP proxy.

Safety — it must never be able to disturb the rest of the machine
-----------------------------------------------------------------
* listens on 127.0.0.1 only, refuses non-loopback peers;
* touches no route, no DNS setting, no environment variable;
* only CONNECT to ports 443/80, and only to hosts on the ALLOWLIST (suffix match) — anything else
  gets 403, so even a mis-pointed client (Claude CLI, the bot…) cannot be routed through WARP by it;
* IP literals are refused (they would bypass the allowlist).

stdlib only. Usage:  warp-doh-proxy [--listen 127.0.0.1:40001] [--socks 127.0.0.1:40000] [--hosts FILE]
                     warp-doh-proxy --check          # is WARP's SOCKS5 reachable?  (exit 0/1)
"""

from __future__ import annotations

import argparse
import asyncio
import ipaddress
import json
import os
import signal
import socket
import struct
import sys
import time
import urllib.parse
import urllib.request

#: Used when the hosts file is missing or empty (domain-suffix match: "missav.ws" covers "www.missav.ws").
DEFAULT_HOSTS = (
    "missav.com", "missav.ai", "missav.ws", "missav.live",
    "123av.com", "123av.ai", "123av.ws", "javxx.com", "njavtv.com",
    "surrit.com",
)
DEFAULT_HOSTS_FILE = os.path.expanduser("~/.config/warp-doh-proxy/hosts")
DOH_URL = "https://1.1.1.1/dns-query"  # by IP: needs no DNS of its own
ALLOWED_PORTS = frozenset({443, 80})


def log(message: str) -> None:
    print(message, file=sys.stderr, flush=True)


class Allowlist:
    """Domain suffixes read from a file (re-read when it changes); built-in defaults without one."""

    def __init__(self, path: str) -> None:
        self.path = path
        self._mtime: float | None = None
        self._domains: list[str] = list(DEFAULT_HOSTS)

    def domains(self) -> list[str]:
        try:
            mtime = os.stat(self.path).st_mtime
        except OSError:
            return self._domains
        if mtime != self._mtime:
            self._mtime = mtime
            with open(self.path, encoding="utf-8") as fh:
                lines = [ln.split("#", 1)[0].strip().lower().lstrip(".") for ln in fh]
            self._domains = [ln for ln in lines if ln] or list(DEFAULT_HOSTS)
        return self._domains

    def allows(self, host: str) -> bool:
        host = host.lower().rstrip(".")
        return any(host == d or host.endswith("." + d) for d in self.domains())


class Resolver:
    """Hostname → public IPs over DoH, cached. A private/loopback answer is a sinkhole and is dropped."""

    def __init__(self) -> None:
        self._cache: dict[str, tuple[float, list[str]]] = {}

    async def resolve(self, host: str) -> list[str]:
        now = time.monotonic()
        hit = self._cache.get(host)
        if hit and hit[0] > now:
            return hit[1]
        ips, ttl = await asyncio.get_running_loop().run_in_executor(None, self._lookup, host)
        if not ips:
            raise OSError(f"cannot resolve {host}")
        self._cache[host] = (now + min(max(ttl, 30), 300), ips)
        return ips

    @staticmethod
    def _is_public(ip: str) -> bool:
        try:
            return ipaddress.ip_address(ip).is_global
        except ValueError:
            return False

    def _lookup(self, host: str) -> tuple[list[str], int]:
        ips: list[str] = []
        ttl = 300
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))  # never an env proxy
        for rtype, code in (("A", 1), ("AAAA", 28)):
            url = f"{DOH_URL}?name={urllib.parse.quote(host)}&type={rtype}"
            try:
                req = urllib.request.Request(url, headers={"accept": "application/dns-json"})
                with opener.open(req, timeout=6) as resp:
                    answers = json.load(resp).get("Answer") or []
            except Exception as exc:  # noqa: BLE001 — DoH down: fall through to the system resolver
                log(f"doh {rtype} {host}: {exc}")
                continue
            for ans in answers:
                if ans.get("type") == code and self._is_public(str(ans.get("data", ""))):
                    ips.append(ans["data"])
                    ttl = min(ttl, int(ans.get("TTL", ttl)))
        if not ips:  # last resort; the sinkhole answer is filtered out by _is_public
            try:
                infos = socket.getaddrinfo(host, None, type=socket.SOCK_STREAM)
                ips = [i[4][0] for i in infos if self._is_public(i[4][0])]
            except OSError:
                pass
        return list(dict.fromkeys(ips)), ttl


async def socks5_connect(socks: tuple[str, int], ip: str, port: int):
    """Open a SOCKS5 tunnel to ``ip:port`` (no name sent — that is the whole point). → (reader, writer)."""
    reader, writer = await asyncio.wait_for(asyncio.open_connection(*socks), 5)
    try:
        writer.write(b"\x05\x01\x00")
        await writer.drain()
        if await asyncio.wait_for(reader.readexactly(2), 5) != b"\x05\x00":
            raise OSError("SOCKS5 server wants authentication")
        addr = ipaddress.ip_address(ip)
        writer.write(b"\x05\x01\x00" + (b"\x01" if addr.version == 4 else b"\x04") + addr.packed
                     + struct.pack("!H", port))
        await writer.drain()
        head = await asyncio.wait_for(reader.readexactly(4), 15)
        if head[1] != 0:
            raise OSError(f"SOCKS5 refused (code {head[1]})")
        n = {1: 4, 4: 16}.get(head[3])
        if n is None:
            n = (await reader.readexactly(1))[0]
        await reader.readexactly(n + 2)
        return reader, writer
    except BaseException:
        writer.close()
        raise


async def _pipe(src: asyncio.StreamReader, dst: asyncio.StreamWriter) -> None:
    try:
        while data := await src.read(65536):
            dst.write(data)
            await dst.drain()
    except (ConnectionError, OSError):
        pass


async def _close(writer: asyncio.StreamWriter) -> None:
    try:
        writer.close()
        await writer.wait_closed()
    except Exception:  # noqa: BLE001
        pass


class Proxy:
    def __init__(self, socks: tuple[str, int], allow: Allowlist) -> None:
        self.socks, self.allow, self.resolver = socks, allow, Resolver()

    @staticmethod
    async def _reply(writer: asyncio.StreamWriter, code: int, text: str) -> None:
        body = text.encode()
        writer.write(f"HTTP/1.1 {code} {text.split(':')[0]}\r\nContent-Type: text/plain\r\n"
                     f"Content-Length: {len(body)}\r\nConnection: close\r\n\r\n".encode() + body)
        try:
            await writer.drain()
        except ConnectionError:
            pass

    async def handle(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        up_writer = None
        try:
            peer = writer.get_extra_info("peername")
            if not peer or not ipaddress.ip_address(peer[0].split("%")[0]).is_loopback:
                return
            try:
                head = await asyncio.wait_for(reader.readuntil(b"\r\n\r\n"), 10)
            except (asyncio.IncompleteReadError, asyncio.LimitOverrunError, asyncio.TimeoutError):
                return
            parts = head.split(b"\r\n", 1)[0].decode("latin-1").split()
            if len(parts) != 3 or parts[0].upper() != "CONNECT":
                return await self._reply(writer, 405, "Method Not Allowed: only CONNECT (https) is supported")
            host, _, port_s = parts[1].rpartition(":")
            host = host.strip("[]").lower()
            if not port_s.isdigit() or int(port_s) not in ALLOWED_PORTS:
                return await self._reply(writer, 403, f"Forbidden: port {port_s!r} is not allowed")
            port = int(port_s)
            try:
                ipaddress.ip_address(host)
                return await self._reply(writer, 403, "Forbidden: IP literals are not allowed")
            except ValueError:
                pass
            if not self.allow.allows(host):
                log(f"deny    {host}:{port} (not on the allowlist)")
                return await self._reply(writer, 403, f"Forbidden: {host} is not on the allowlist")
            try:
                ips = await self.resolver.resolve(host)
            except OSError as exc:
                log(f"nodns   {host}: {exc}")
                return await self._reply(writer, 502, f"Bad Gateway: {exc}")
            last: BaseException | None = None
            up_reader = None
            for ip in ips[:3]:
                try:
                    up_reader, up_writer = await socks5_connect(self.socks, ip, port)
                    break
                except (OSError, asyncio.TimeoutError, asyncio.IncompleteReadError) as exc:
                    last = exc
            if up_writer is None or up_reader is None:
                log(f"fail    {host}:{port}: {last!r}")
                return await self._reply(writer, 502, f"Bad Gateway: WARP SOCKS5 unavailable ({last})")
            log(f"tunnel  {host}:{port}")
            writer.write(b"HTTP/1.1 200 Connection Established\r\n\r\n")
            await writer.drain()
            tasks = {asyncio.ensure_future(_pipe(reader, up_writer)),
                     asyncio.ensure_future(_pipe(up_reader, writer))}
            _, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
            for task in pending:
                task.cancel()
        except (ConnectionError, OSError):
            pass
        finally:
            if up_writer is not None:
                await _close(up_writer)
            await _close(writer)


def _hostport(text: str) -> tuple[str, int]:
    host, _, port = text.rpartition(":")
    return host or "127.0.0.1", int(port)


async def _check(socks: tuple[str, int]) -> int:
    try:
        _, writer = await socks5_connect(socks, "1.1.1.1", 443)
        await _close(writer)
        print(f"WARP SOCKS5 {socks[0]}:{socks[1]} reachable")
        return 0
    except Exception as exc:  # noqa: BLE001
        print(f"WARP SOCKS5 {socks[0]}:{socks[1]} NOT reachable: {exc!r}", file=sys.stderr)
        return 1


async def _serve(listen: tuple[str, int], proxy: Proxy) -> None:
    server = await asyncio.start_server(proxy.handle, *listen)
    stop = asyncio.Event()
    for sig in (signal.SIGINT, signal.SIGTERM):
        asyncio.get_running_loop().add_signal_handler(sig, stop.set)
    log(f"listening on {listen[0]}:{listen[1]} → WARP SOCKS5 {proxy.socks[0]}:{proxy.socks[1]}; "
        f"allowlist: {', '.join(proxy.allow.domains())}")
    async with server:
        await stop.wait()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--listen", default="127.0.0.1:40001")
    ap.add_argument("--socks", default="127.0.0.1:40000", help="WARP proxy-mode SOCKS5 (warp-cli mode proxy)")
    ap.add_argument("--hosts", default=DEFAULT_HOSTS_FILE, help="allowlist file: one domain suffix per line")
    ap.add_argument("--check", action="store_true", help="only test that WARP's SOCKS5 answers")
    args = ap.parse_args()
    socks, listen = _hostport(args.socks), _hostport(args.listen)
    if not ipaddress.ip_address(listen[0]).is_loopback:
        ap.error("--listen must be a loopback address")
    if args.check:
        return asyncio.run(_check(socks))
    asyncio.run(_serve(listen, Proxy(socks, Allowlist(args.hosts))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
