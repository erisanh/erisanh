pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Cliphist - Clipboard history service using cliphist
 */
Singleton {
    id: root

    property string cliphistBinary: "cliphist"
    property list<string> entries: []

    readonly property var preparedEntries: entries.map(a => ({
        name: Fuzzy.prepare(`${a.replace(/^\s*\S+\s+/, "")}`),
        entry: a
    }))

    /**
     * Fuzzy search clipboard entries
     * @param {string} search - The search query
     * @returns {list<string>} Matching clipboard entries
     */
    function fuzzyQuery(search) {
        if (search.trim() === "") {
            return entries;
        }

        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => r.obj.entry);
    }

    /**
     * Check if a clipboard entry is an image
     * @param {string} entry - The clipboard entry
     * @returns {boolean} True if entry is an image
     */
    function entryIsImage(entry) {
        return !!(/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry));
    }

    /**
     * Refresh the clipboard history
     */
    function refresh() {
        readProc.buffer = [];
        readProc.running = true;
    }

    /**
     * Copy a clipboard entry to the clipboard
     * @param {string} entry - The clipboard entry to copy
     */
    function copy(entry) {
        Quickshell.execDetached(["bash", "-c", `printf '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy`]);
    }

    /**
     * Delete a clipboard entry
     * @param {string} entry - The clipboard entry to delete
     */
    function deleteEntry(entry) {
        deleteProc.entry = entry;
        deleteProc.running = true;
    }

    Process {
        id: deleteProc
        property string entry: ""
        command: ["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(deleteProc.entry)}' | ${root.cliphistBinary} delete`]
        onExited: (exitCode, exitStatus) => {
            deleteProc.entry = "";
            root.refresh();
        }
    }

    // Auto-refresh when clipboard changes
    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            delayedUpdateTimer.restart();
        }
    }

    Timer {
        id: delayedUpdateTimer
        interval: 100
        repeat: false
        onTriggered: {
            root.refresh();
        }
    }

    Process {
        id: readProc
        property list<string> buffer: []

        command: [root.cliphistBinary, "list"]

        stdout: SplitParser {
            onRead: (line) => {
                readProc.buffer.push(line);
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.entries = readProc.buffer;
            } else {
                console.error("[Cliphist] Failed to refresh with code", exitCode, "and status", exitStatus);
            }
        }
    }

    // Initialize on load
    Component.onCompleted: {
        refresh();
    }
}
