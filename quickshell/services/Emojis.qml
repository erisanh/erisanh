pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Emojis - Emoji picker service loading from bundled emoji data
 */
Singleton {
    id: root

    property list<var> list: []

    readonly property var preparedEntries: list.map(a => ({
        name: Fuzzy.prepare(`${a}`),
        entry: a
    }))

    /**
     * Fuzzy search emojis
     * @param {string} search - The search query
     * @returns {list<string>} Matching emoji entries
     */
    function fuzzyQuery(search) {
        if (search.trim() === "") {
            return list.slice(0, 50); // Return first 50 emojis when empty
        }

        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => r.obj.entry);
    }

    /**
     * Load emojis from the data file
     */
    function load() {
        emojiFileView.reload();
    }

    function updateEmojis(fileContent) {
        const lines = fileContent.split("\n");
        const emojis = lines.filter(line => line.trim() !== "");
        root.list = emojis.map(line => line.trim());
    }

    FileView {
        id: emojiFileView
        path: Quickshell.shellPath("assets/emojis.txt")
        onLoadedChanged: {
            if (loaded) {
                const fileContent = emojiFileView.text();
                root.updateEmojis(fileContent);
            }
        }
    }

    // Initialize on load
    Component.onCompleted: {
        load();
    }
}
