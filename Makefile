# Orca (AUR: onorca-bin, binary 'orca-ide').

ORCA_PKG  := onorca-bin
ORCA_PROC := /opt/Orca/orca-ide

# WiFi demo (pywifi) — educational only, use with your own network.
WIFI_SCRIPT := scripts/pywifi_demo.py
WIFI_VENV   := .venv

.DEFAULT_GOAL := help
.PHONY: help orca-version orca-up orca-serve-install orca-serve-status wifi-venv wifi-demo

help: ## Show this help
	@echo "Usage: make <target>"
	@echo
	@awk -F':.*## ' '/^[a-zA-Z_-]+:.*## / {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

orca-version: ## Show installed Orca version vs latest available on AUR
	@cur=$$(pacman -Q $(ORCA_PKG) 2>/dev/null | awk '{print $$2}'); \
	new=$$(yay -Si $(ORCA_PKG) 2>/dev/null | awk '/^Version/ {print $$3}'); \
	echo "installed: $${cur:-not installed}"; \
	echo "latest:    $${new:-unknown (AUR unreachable)}"; \
	if [ -z "$$new" ]; then :; \
	elif [ "$$cur" = "$$new" ]; then echo "=> up to date"; \
	else echo "=> update available (run: make orca-up)"; fi

orca-up: ## Upgrade Orca to the latest version, then restart it (safe to run inside Orca)
	@echo "installed: $$(pacman -Q $(ORCA_PKG) 2>/dev/null || echo 'not installed')"
	yay -S --noconfirm --answerclean None --answerdiff None $(YAY_FLAGS) $(ORCA_PKG)
	@echo "now:       $$(pacman -Q $(ORCA_PKG))"
	@echo "==> Restarting Orca..."
	@# Only the bare main process matches '$$'; the terminal daemon (daemon-entry.js)
	@# has arguments, so it is left alone. Runs in its own scope + session so it
	@# survives Orca closing the terminal it was launched from.
	@systemd-run --user --scope --quiet -- setsid -f sh -c '\
		pkill -f "^$(ORCA_PROC)$$" 2>/dev/null; \
		for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do \
			pgrep -f "^$(ORCA_PROC)$$" >/dev/null || break; sleep 0.5; done; \
		pkill -9 -f "^$(ORCA_PROC)$$" 2>/dev/null; \
		exec setsid $(ORCA_PROC) >/dev/null 2>&1 </dev/null' >/dev/null 2>&1

orca-serve-install: ## Install + enable the headless Orca boot service (systemd --user)
	@bash setup-app.sh orca-serve

orca-serve-status: ## Show the headless Orca service state and recent log
	@systemctl --user status orca-serve --no-pager -n 15 || true

wifi-venv: ## Create .venv and install pywifi (used by wifi-demo)
	@test -d $(WIFI_VENV) || python3 -m venv $(WIFI_VENV)
	@$(WIFI_VENV)/bin/pip install -q --upgrade pip pywifi

wifi-demo: wifi-venv ## Run pywifi scan+connect demo: make wifi-demo SSID="Name" PASS="secret"
	@test -n "$(SSID)" && test -n "$(PASS)" || { \
		echo "Usage: make wifi-demo SSID=\"<ssid>\" PASS=\"<password>\""; exit 1; }
	sudo $(WIFI_VENV)/bin/python $(WIFI_SCRIPT) "$(SSID)" "$(PASS)"
