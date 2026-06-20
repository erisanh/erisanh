pragma Singleton
import qs.modules.common.functions
import Quickshell

/**
 * AppSearch - Eases fuzzy searching for applications by name and provides icon guessing
 */
Singleton {
    id: root

    // Substitutions for common app names to their icon names
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
    })

    property var regexSubstitutions: [
        { "regex": /^steam_app_(\d+)$/, "replace": "steam_icon_$1" },
        { "regex": /Minecraft.*/, "replace": "minecraft" },
        { "regex": /.*polkit.*/, "replace": "system-lock-screen" },
        { "regex": /gcr.prompter/, "replace": "system-lock-screen" }
    ]

    // Deduped list of all desktop entries
    readonly property list<DesktopEntry> allApps: Array.from(DesktopEntries.applications.values)
        .filter((app, index, self) => 
            index === self.findIndex((t) => t.id === app.id)
        )

    // Prepared names for fuzzy search
    readonly property var preppedNames: allApps.map(a => ({
        name: Fuzzy.prepare(`${a.name} `),
        entry: a
    }))

    // Prepared icons for fuzzy search
    readonly property var preppedIcons: allApps.map(a => ({
        name: Fuzzy.prepare(`${a.icon} `),
        entry: a
    }))

    /**
     * Fuzzy search for applications by name
     * @param {string} search - The search query
     * @returns {list<DesktopEntry>} Matching desktop entries
     */
    function fuzzyQuery(search) {
        return Fuzzy.go(search, preppedNames, {
            all: true,
            key: "name"
        }).map(r => r.obj.entry);
    }

    /**
     * Check if an icon exists
     * @param {string} iconName - The icon name to check
     * @returns {boolean} True if icon exists
     */
    function iconExists(iconName) {
        if (!iconName || iconName.length === 0) return false;
        return (Quickshell.iconPath(iconName, true).length > 0) 
            && !iconName.includes("image-missing");
    }

    function getReverseDomainNameAppName(str) {
        return str.split('.').slice(-1)[0];
    }

    function getKebabNormalizedAppName(str) {
        return str.toLowerCase().replace(/\s+/g, "-");
    }

    function getUnderscoreToKebabAppName(str) {
        return str.toLowerCase().replace(/_/g, "-");
    }

    /**
     * Guess the icon name for a window class name
     * @param {string} str - The window class name
     * @returns {string} The guessed icon name
     */
    function guessIcon(str) {
        if (!str || str.length === 0) return "image-missing";

        // Quickshell's desktop entry lookup
        const entry = DesktopEntries.byId(str);
        if (entry) return entry.icon;

        // Normal substitutions
        if (substitutions[str]) return substitutions[str];
        if (substitutions[str.toLowerCase()]) return substitutions[str.toLowerCase()];

        // Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(substitution.regex, substitution.replace);
            if (replacedName !== str) return replacedName;
        }

        // Icon exists -> return as is
        if (iconExists(str)) return str;

        // Simple guesses
        const lowercased = str.toLowerCase();
        if (iconExists(lowercased)) return lowercased;

        const reverseDomainNameAppName = getReverseDomainNameAppName(str);
        if (iconExists(reverseDomainNameAppName)) return reverseDomainNameAppName;

        const lowercasedDomainNameAppName = reverseDomainNameAppName.toLowerCase();
        if (iconExists(lowercasedDomainNameAppName)) return lowercasedDomainNameAppName;

        const kebabNormalizedGuess = getKebabNormalizedAppName(str);
        if (iconExists(kebabNormalizedGuess)) return kebabNormalizedGuess;

        const underscoreToKebabGuess = getUnderscoreToKebabAppName(str);
        if (iconExists(underscoreToKebabGuess)) return underscoreToKebabGuess;

        // Search in desktop entries by icon
        const iconSearchResults = Fuzzy.go(str, preppedIcons, {
            all: true,
            key: "name"
        }).map(r => r.obj.entry);
        if (iconSearchResults.length > 0) {
            const guess = iconSearchResults[0].icon;
            if (iconExists(guess)) return guess;
        }

        // Search in desktop entries by name
        const nameSearchResults = root.fuzzyQuery(str);
        if (nameSearchResults.length > 0) {
            const guess = nameSearchResults[0].icon;
            if (iconExists(guess)) return guess;
        }

        // Quickshell's heuristic lookup
        const heuristicEntry = DesktopEntries.heuristicLookup(str);
        if (heuristicEntry) return heuristicEntry.icon;

        // Give up
        return "application-x-executable";
    }
}
