pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common.functions

/**
 * Appearance - Unified Material 3 design system singleton
 * Replaces Colors.qml and LauncherAppearance.qml with:
 * - m3colors: All 50+ matugen scheme colors
 * - colors: Computed layer system + semantic colors + status colors
 * - font, rounding, sizes, animation: UI configuration
 */
Singleton {
    id: root

    // Transparency settings (opaque by default)
    property real backgroundTransparency: 0
    property real contentTransparency: 0

    // Material 3 color scheme (from matugen - source #95CDF7)
    property QtObject m3colors: QtObject {
        readonly property bool darkmode: true

        // Primary
        readonly property color m3primary: "#95CDF7"
        readonly property color m3onPrimary: "#00344E"
        readonly property color m3primaryContainer: "#004C6E"
        readonly property color m3onPrimaryContainer: "#C9E6FF"
        readonly property color m3inversePrimary: "#006590"
        readonly property color m3primaryFixed: "#C9E6FF"
        readonly property color m3primaryFixedDim: "#8BCBF5"
        readonly property color m3onPrimaryFixed: "#001E2F"
        readonly property color m3onPrimaryFixedVariant: "#004C6E"

        // Secondary
        readonly property color m3secondary: "#B7C9D9"
        readonly property color m3onSecondary: "#22323F"
        readonly property color m3secondaryContainer: "#384956"
        readonly property color m3onSecondaryContainer: "#D3E5F5"
        readonly property color m3secondaryFixed: "#D3E5F5"
        readonly property color m3secondaryFixedDim: "#B7C9D9"
        readonly property color m3onSecondaryFixed: "#0C1D29"
        readonly property color m3onSecondaryFixedVariant: "#384956"

        // Tertiary
        readonly property color m3tertiary: "#CEC0E8"
        readonly property color m3onTertiary: "#352B4B"
        readonly property color m3tertiaryContainer: "#4C4163"
        readonly property color m3onTertiaryContainer: "#EADDFF"
        readonly property color m3tertiaryFixed: "#EADDFF"
        readonly property color m3tertiaryFixedDim: "#D1C1E9"
        readonly property color m3onTertiaryFixed: "#201535"
        readonly property color m3onTertiaryFixedVariant: "#4C4163"

        // Error
        readonly property color m3error: "#FFB4AB"
        readonly property color m3onError: "#690005"
        readonly property color m3errorContainer: "#93000A"
        readonly property color m3onErrorContainer: "#FFDAD6"

        // Surface & Background
        readonly property color m3background: "#101417"
        readonly property color m3onBackground: "#E0E3E8"
        readonly property color m3surface: "#101417"
        readonly property color m3surfaceDim: "#101417"
        readonly property color m3surfaceBright: "#353A3E"
        readonly property color m3surfaceContainerLowest: "#0A0F12"
        readonly property color m3surfaceContainerLow: "#181C20"
        readonly property color m3surfaceContainer: "#1C2024"
        readonly property color m3surfaceContainerHigh: "#262A2E"
        readonly property color m3surfaceContainerHighest: "#313539"
        readonly property color m3onSurface: "#E0E3E8"
        readonly property color m3surfaceVariant: "#41474D"
        readonly property color m3onSurfaceVariant: "#C1C7CE"
        readonly property color m3inverseSurface: "#E0E3E8"
        readonly property color m3inverseOnSurface: "#2D3135"

        // Outline
        readonly property color m3outline: "#8B9198"
        // readonly property color m3outlineVariant: "#41474D"
        readonly property color m3outlineVariant: "#313539"

        // Shadow & Scrim
        readonly property color m3shadow: "#000000"
        readonly property color m3scrim: "#000000"
        readonly property color m3surfaceTint: "#95CDF7"
    }

    // Computed semantic colors with layer system
    property QtObject colors: QtObject {
        // Subtext
        readonly property color colSubtext: m3colors.m3outline

        // Layer 0 - Base background
        readonly property color colLayer0Base: m3colors.m3background
        readonly property color colLayer0: ColorUtils.transparentize(colLayer0Base, root.backgroundTransparency)
        readonly property color colOnLayer0: m3colors.m3onBackground
        readonly property color colLayer0Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer0Base, colOnLayer0, 0.9), root.contentTransparency)
        readonly property color colLayer0Active: ColorUtils.transparentize(ColorUtils.mix(colLayer0Base, colOnLayer0, 0.8), root.contentTransparency)
        readonly property color colLayer0Border: ColorUtils.mix(m3colors.m3outlineVariant, colLayer0Base, 0.4)

        // Layer 1 - Surface (current Colors.surface)
        readonly property color colLayer1Base: m3colors.m3surfaceContainerLow
        readonly property color colLayer1: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(colLayer0Base, colLayer1Base, 1 - root.contentTransparency) : colLayer1Base
        readonly property color colOnLayer1: m3colors.m3onSurfaceVariant
        readonly property color colOnLayer1Inactive: ColorUtils.mix(colOnLayer1, colLayer1, 0.45)
        readonly property color colLayer1Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer1Base, colOnLayer1, 0.92), root.contentTransparency)
        readonly property color colLayer1Active: ColorUtils.transparentize(ColorUtils.mix(colLayer1Base, colOnLayer1, 0.85), root.contentTransparency)

        // Layer 2 - Surface Container (current Colors.surfaceHover)
        readonly property color colLayer2Base: m3colors.m3surfaceContainer
        readonly property color colLayer2: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(colLayer1Base, colLayer2Base, 1 - root.contentTransparency) : colLayer2Base
        readonly property color colLayer2Hover: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, colOnLayer2, 0.90), 1 - root.contentTransparency) : ColorUtils.mix(colLayer2Base, colOnLayer2, 0.90)
        readonly property color colLayer2Active: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, colOnLayer2, 0.80), 1 - root.contentTransparency) : ColorUtils.mix(colLayer2Base, colOnLayer2, 0.80)
        readonly property color colLayer2Disabled: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(colLayer1Base, ColorUtils.mix(colLayer2Base, m3colors.m3background, 0.8), 1 - root.contentTransparency) : ColorUtils.mix(colLayer2Base, m3colors.m3background, 0.8)
        readonly property color colOnLayer2: m3colors.m3onSurface
        readonly property color colOnLayer2Disabled: ColorUtils.mix(colOnLayer2, m3colors.m3background, 0.4)

        // Layer 3 - Surface Container High (current Colors.surfaceContainerHighest)
        readonly property color colLayer3Base: m3colors.m3surfaceContainerHigh
        readonly property color colLayer3: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(colLayer2Base, colLayer3Base, 1 - root.contentTransparency) : colLayer3Base
        readonly property color colLayer3Hover: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(colLayer2Base, ColorUtils.mix(colLayer3Base, colOnLayer3, 0.90), 1 - root.contentTransparency) : ColorUtils.mix(colLayer3Base, colOnLayer3, 0.90)
        readonly property color colLayer3Active: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(colLayer2Base, ColorUtils.mix(colLayer3Base, colOnLayer3, 0.80), 1 - root.contentTransparency) : ColorUtils.mix(colLayer3Base, colOnLayer3, 0.80)
        readonly property color colOnLayer3: m3colors.m3onSurface

        // Layer 4 - Surface Container Highest
        readonly property color colLayer4Base: m3colors.m3surfaceContainerHighest
        readonly property color colLayer4: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(colLayer3Base, colLayer4Base, 1 - root.contentTransparency) : colLayer4Base
        readonly property color colLayer4Hover: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(colLayer3Base, ColorUtils.mix(colLayer4Base, colOnLayer4, 0.90), 1 - root.contentTransparency) : ColorUtils.mix(colLayer4Base, colOnLayer4, 0.90)
        readonly property color colLayer4Active: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(colLayer3Base, ColorUtils.mix(colLayer4Base, colOnLayer4, 0.80), 1 - root.contentTransparency) : ColorUtils.mix(colLayer4Base, colOnLayer4, 0.80)
        readonly property color colOnLayer4: m3colors.m3onSurface

        // Primary semantic colors
        readonly property color colPrimary: m3colors.m3primary
        readonly property color colOnPrimary: m3colors.m3onPrimary
        readonly property color colPrimaryHover: ColorUtils.mix(colPrimary, colLayer1Hover, 0.87)
        readonly property color colPrimaryActive: ColorUtils.mix(colPrimary, colLayer1Active, 0.7)
        readonly property color colPrimaryContainer: m3colors.m3primaryContainer
        readonly property color colPrimaryContainerHover: ColorUtils.mix(colPrimaryContainer, colOnPrimaryContainer, 0.9)
        readonly property color colPrimaryContainerActive: ColorUtils.mix(colPrimaryContainer, colOnPrimaryContainer, 0.8)
        readonly property color colOnPrimaryContainer: m3colors.m3onPrimaryContainer

        // Secondary semantic colors
        readonly property color colSecondary: m3colors.m3secondary
        readonly property color colSecondaryHover: ColorUtils.mix(m3colors.m3secondary, colLayer1Hover, 0.85)
        readonly property color colSecondaryActive: ColorUtils.mix(m3colors.m3secondary, colLayer1Active, 0.4)
        readonly property color colOnSecondary: m3colors.m3onSecondary
        readonly property color colSecondaryContainer: m3colors.m3secondaryContainer
        readonly property color colSecondaryContainerHover: ColorUtils.mix(m3colors.m3secondaryContainer, m3colors.m3onSecondaryContainer, 0.90)
        readonly property color colSecondaryContainerActive: ColorUtils.mix(m3colors.m3secondaryContainer, m3colors.m3onSecondaryContainer, 0.54)
        readonly property color colOnSecondaryContainer: m3colors.m3onSecondaryContainer

        // Tertiary semantic colors
        readonly property color colTertiary: m3colors.m3tertiary
        readonly property color colTertiaryHover: ColorUtils.mix(m3colors.m3tertiary, colLayer1Hover, 0.85)
        readonly property color colTertiaryActive: ColorUtils.mix(m3colors.m3tertiary, colLayer1Active, 0.4)
        readonly property color colOnTertiary: m3colors.m3onTertiary
        readonly property color colTertiaryContainer: m3colors.m3tertiaryContainer
        readonly property color colTertiaryContainerHover: ColorUtils.mix(colTertiaryContainer, colOnTertiaryContainer, 0.90)
        readonly property color colTertiaryContainerActive: ColorUtils.mix(colTertiaryContainer, colLayer1Active, 0.54)
        readonly property color colOnTertiaryContainer: m3colors.m3onTertiaryContainer

        // Surface semantic colors (for compatibility)
        readonly property color colBackgroundSurfaceContainer: ColorUtils.transparentize(m3colors.m3surfaceContainer, root.backgroundTransparency)
        readonly property color colSurfaceContainerLow: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(m3colors.m3background, m3colors.m3surfaceContainerLow, 1 - root.contentTransparency) : m3colors.m3surfaceContainerLow
        readonly property color colSurfaceContainer: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(m3colors.m3surfaceContainerLow, m3colors.m3surfaceContainer, 1 - root.contentTransparency) : m3colors.m3surfaceContainer
        readonly property color colSurfaceContainerHigh: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(m3colors.m3surfaceContainer, m3colors.m3surfaceContainerHigh, 1 - root.contentTransparency) : m3colors.m3surfaceContainerHigh
        readonly property color colSurfaceContainerHighest: root.contentTransparency > 0 ? ColorUtils.solveOverlayColor(m3colors.m3surfaceContainerHigh, m3colors.m3surfaceContainerHighest, 1 - root.contentTransparency) : m3colors.m3surfaceContainerHighest
        readonly property color colSurfaceContainerHighestHover: ColorUtils.mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.95)
        readonly property color colSurfaceContainerHighestActive: ColorUtils.mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.85)
        readonly property color colOnSurface: m3colors.m3onSurface
        readonly property color colOnSurfaceVariant: m3colors.m3onSurfaceVariant

        // Outline
        readonly property color colOutline: m3colors.m3outline
        readonly property color colOutlineVariant: m3colors.m3outlineVariant

        // Error semantic colors
        readonly property color colError: m3colors.m3error
        readonly property color colErrorHover: ColorUtils.mix(m3colors.m3error, colLayer1Hover, 0.85)
        readonly property color colErrorActive: ColorUtils.mix(m3colors.m3error, colLayer1Active, 0.7)
        readonly property color colOnError: m3colors.m3onError
        readonly property color colErrorContainer: m3colors.m3errorContainer
        readonly property color colErrorContainerHover: ColorUtils.mix(m3colors.m3errorContainer, m3colors.m3onErrorContainer, 0.90)
        readonly property color colErrorContainerActive: ColorUtils.mix(m3colors.m3errorContainer, m3colors.m3onErrorContainer, 0.70)
        readonly property color colOnErrorContainer: m3colors.m3onErrorContainer

        // Misc
        readonly property color colTooltip: m3colors.m3inverseSurface
        readonly property color colOnTooltip: m3colors.m3inverseOnSurface
        readonly property color colScrim: ColorUtils.transparentize(m3colors.m3scrim, 0.5)
        readonly property color colShadow: ColorUtils.transparentize(m3colors.m3shadow, 0.7)

        // Status colors (custom, not from matugen)
        readonly property color colBatteryCharging: "#1BCA4B"
        readonly property color colBatteryCritical: "#F60B00"
        readonly property color colPowerButton: "#DD5C82"
        readonly property color colEmptyWorkspace: "#77767b"
        readonly property color colArchBlue: "#0F94D2"
    }

    // Font configuration
    readonly property QtObject font: QtObject {
        readonly property QtObject family: QtObject {
            readonly property string main: "sans-serif"
            readonly property string monospace: "monospace"
        }
        readonly property QtObject pixelSize: QtObject {
            readonly property int smallest: 10
            readonly property int smaller: 12
            readonly property int small: 15
            readonly property int normal: 16
            readonly property int large: 17
            readonly property int larger: 19
            readonly property int huge: 22
            readonly property int hugeass: 24
        }
    }

    // Rounding values
    readonly property QtObject rounding: QtObject {
        readonly property int small: 12
        readonly property int normal: 17
        readonly property int large: 23
        readonly property int full: 9999
    }

    // Size values
    readonly property QtObject sizes: QtObject {
        readonly property real elevationMargin: 10
        readonly property real searchWidthCollapsed: 210
        readonly property real searchWidth: 450
    }

    // Animation configuration
    readonly property QtObject animation: QtObject {
        readonly property QtObject elementMove: QtObject {
            readonly property int duration: 200
            readonly property int type: Easing.OutQuad
            readonly property var bezierCurve: [0.2, 0.0, 0.0, 1.0]
            readonly property Component numberAnimation: Component {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }
            readonly property Component colorAnimation: Component {
                ColorAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }
        }
        readonly property QtObject elementMoveFast: QtObject {
            readonly property int duration: 100
            readonly property Component colorAnimation: Component {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }
            readonly property Component numberAnimation: Component {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }
        }
    }
}
