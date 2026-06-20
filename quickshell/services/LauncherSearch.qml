pragma Singleton

import qs.modules.common.models
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * LauncherSearch - Orchestrates search across apps, clipboard, emojis, and calculator
 */
Singleton {
    id: root

    // Search prefixes
    readonly property string prefixClipboard: ";"
    readonly property string prefixEmojis: ":"
    readonly property string prefixMath: "="

    // Current search query
    property string query: ""

    // Math calculation result
    property string mathResult: ""

    // Result limit
    readonly property int resultLimit: 20

    // Debounce timer for math calculations
    Timer {
        id: mathTimer
        interval: 300
        onTriggered: {
            let expr = root.query;
            if (expr.startsWith(root.prefixMath)) {
                expr = expr.slice(root.prefixMath.length);
            }
            if (expr.trim() !== "") {
                mathProc.calculateExpression(expr);
            }
        }
    }

    Process {
        id: mathProc
        property list<string> baseCommand: ["qalc", "-t"]
        function calculateExpression(expression) {
            mathProc.running = false;
            mathProc.command = baseCommand.concat(expression);
            mathProc.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                root.mathResult = data;
            }
        }
    }

    // Helper function to create app result with actions
    function createAppResult(entry) {
        // Map desktop entry actions to LauncherSearchResult actions
        const entryActions = (entry.actions ?? []).map(action => {
            return resultComp.createObject(null, {
                name: action.name,
                iconName: action.icon || "open_in_new",
                iconType: action.icon ? LauncherSearchResult.IconType.System : LauncherSearchResult.IconType.Material,
                execute: () => {
                    action.execute();
                }
            });
        });

        return resultComp.createObject(null, {
            type: "App",
            id: entry.id,
            name: entry.name,
            iconName: entry.icon,
            iconType: LauncherSearchResult.IconType.System,
            verb: "Open",
            execute: () => {
                entry.execute();
            },
            comment: entry.comment,
            genericName: entry.genericName,
            keywords: entry.keywords,
            actions: entryActions
        });
    }

    // Computed results based on query
    property list<var> results: {
        // Empty query = show all apps
        if (root.query === "") {
            return AppSearch.allApps.map(entry => root.createAppResult(entry));
        }

        // Clipboard search
        if (root.query.startsWith(root.prefixClipboard)) {
            const searchString = StringUtils.cleanPrefix(root.query, root.prefixClipboard);
            return Cliphist.fuzzyQuery(searchString).map(entry => {
                const type = `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`;
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: StringUtils.cleanCliphistEntry(entry),
                    verb: "Copy",
                    type: type,
                    iconName: "edit-paste-symbolic.svg",
                    iconType: LauncherSearchResult.IconType.Asset,
                    execute: () => {
                        Cliphist.copy(entry);
                    },
                    actions: [resultComp.createObject(null, {
                            name: "Copy",
                            iconName: "edit-copy-symbolic.svg",
                            iconType: LauncherSearchResult.IconType.Asset,
                            execute: () => {
                                Cliphist.copy(entry);
                            }
                        }), resultComp.createObject(null, {
                            name: "Delete",
                            iconName: "user-trash-full-symbolic.svg",
                            iconType: LauncherSearchResult.IconType.Asset,
                            execute: () => {
                                Cliphist.deleteEntry(entry);
                            }
                        })]
                });
            }).filter(Boolean);
        }

        // Emoji search
        if (root.query.startsWith(root.prefixEmojis)) {
            const searchString = StringUtils.cleanPrefix(root.query, root.prefixEmojis);
            return Emojis.fuzzyQuery(searchString).map(entry => {
                const emoji = entry.match(/^\s*(\S+)/)?.[1] || "";
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: entry.replace(/^\s*\S+\s+/, ""),
                    iconName: emoji,
                    iconType: LauncherSearchResult.IconType.Text,
                    verb: "Copy",
                    type: "Emoji",
                    execute: () => {
                        Quickshell.clipboardText = emoji;
                    }
                });
            }).filter(Boolean);
        }

        // Math calculation
        if (root.query.startsWith(root.prefixMath) || /^\d/.test(root.query)) {
            mathTimer.restart();
            const mathResultObject = resultComp.createObject(null, {
                name: root.mathResult || "Calculating...",
                verb: "Copy",
                type: "Math result",
                fontType: LauncherSearchResult.FontType.Monospace,
                iconName: "calculate",
                iconType: LauncherSearchResult.IconType.Material,
                execute: () => {
                    Quickshell.clipboardText = root.mathResult;
                }
            });

            // If starts with = prefix, only show math result
            if (root.query.startsWith(root.prefixMath)) {
                return [mathResultObject];
            }

            // Otherwise, also show app results
            const appResults = AppSearch.fuzzyQuery(root.query).map(entry => root.createAppResult(entry));

            return [mathResultObject, ...appResults];
        }

        // Default: app search
        return AppSearch.fuzzyQuery(root.query).map(entry => root.createAppResult(entry));
    }

    Component {
        id: resultComp
        LauncherSearchResult {}
    }
}
