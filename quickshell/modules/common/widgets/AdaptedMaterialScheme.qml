import QtQuick
import qs.modules.common
import qs.modules.common.functions

/**
 * Material color scheme adapted to a given color. It's incomplete but enough for what we need...
 */
QtObject {
    id: root
    required property color sourceColor
    readonly property bool colorIsDark: sourceColor.hslLightness < 0.5

    // Material 3 base colors (from Appearance singleton - blue theme)
    readonly property color m3background: Appearance.m3colors.m3background
    readonly property color m3onBackground: Appearance.colors.colOnLayer0
    readonly property color m3surfaceContainerLow: Appearance.m3colors.m3surfaceContainerLow
    readonly property color m3onSurfaceVariant: Appearance.colors.colSubtext
    readonly property color m3primary: Appearance.m3colors.m3primary
    readonly property color m3onPrimary: Appearance.m3colors.m3onPrimary
    readonly property color m3secondaryContainer: Appearance.m3colors.m3secondaryContainer
    readonly property color m3onSecondaryContainer: Appearance.m3colors.m3onSecondaryContainer
    readonly property color m3outline: Appearance.m3colors.m3outline

    // Computed base colors from Material 3 scheme
    readonly property color baseLayer0: m3background
    readonly property color baseLayer1: m3surfaceContainerLow
    readonly property color baseOnLayer0: m3onBackground
    readonly property color baseOnLayer1: m3onSurfaceVariant
    readonly property color basePrimary: m3primary
    readonly property color basePrimaryHover: ColorUtils.mix(m3primary, Appearance.colors.colLayer1, 0.87)
    readonly property color basePrimaryActive: ColorUtils.mix(m3primary, Appearance.colors.colLayer1, 0.7)
    readonly property color baseSecondary: Appearance.colors.colSubtext
    readonly property color baseSecondaryContainer: m3secondaryContainer
    readonly property color baseSecondaryContainerHover: ColorUtils.mix(m3secondaryContainer, m3onSecondaryContainer, 0.90)
    readonly property color baseSecondaryContainerActive: ColorUtils.mix(m3secondaryContainer, m3onSecondaryContainer, 0.54)
    readonly property color baseOnPrimary: m3onPrimary
    readonly property color baseOnSecondaryContainer: m3onSecondaryContainer

    // Adapted colors - blend with source color
    property color colLayer0: ColorUtils.mix(baseLayer0, root.sourceColor, (colorIsDark) ? 0.6 : 0.5)
    property color colLayer1: ColorUtils.mix(baseLayer1, root.sourceColor, 0.5)
    property color colOnLayer0: ColorUtils.mix(baseOnLayer0, root.sourceColor, 0.5)
    property color colOnLayer1: ColorUtils.mix(baseOnLayer1, root.sourceColor, 0.5)
    property color colSubtext: ColorUtils.mix(baseOnLayer1, root.sourceColor, 0.5)
    property color colPrimary: ColorUtils.mix(ColorUtils.adaptToAccent(basePrimary, root.sourceColor), root.sourceColor, 0.5)
    property color colPrimaryHover: ColorUtils.mix(ColorUtils.adaptToAccent(basePrimaryHover, root.sourceColor), root.sourceColor, 0.3)
    property color colPrimaryActive: ColorUtils.mix(ColorUtils.adaptToAccent(basePrimaryActive, root.sourceColor), root.sourceColor, 0.3)
    property color colSecondary: ColorUtils.mix(ColorUtils.adaptToAccent(baseSecondary, root.sourceColor), root.sourceColor, 0.5)
    property color colSecondaryContainer: ColorUtils.mix(baseSecondaryContainer, root.sourceColor, 0.15)
    property color colSecondaryContainerHover: ColorUtils.mix(baseSecondaryContainerHover, root.sourceColor, 0.3)
    property color colSecondaryContainerActive: ColorUtils.mix(baseSecondaryContainerActive, root.sourceColor, 0.5)
    property color colOnPrimary: ColorUtils.mix(ColorUtils.adaptToAccent(baseOnPrimary, root.sourceColor), root.sourceColor, 0.5)
    property color colOnSecondaryContainer: ColorUtils.mix(baseOnSecondaryContainer, root.sourceColor, 0.5)
}
