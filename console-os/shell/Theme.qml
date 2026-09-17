import QtQuick

// Jetons de design centralisés — voir docs/design-system.md.
// Valeurs alignées sur l'identité déjà implémentée dans Main.qml (palette
// sombre teal/mint), pas sur les maquettes tierces (voir .ai/DECISIONS.md,
// ADR-004). Instancié une fois dans Main.qml (`Theme { id: theme }`) et
// partagé avec les composants enfants (ex. QuickMenu) via une propriété.
QtObject {
    readonly property color colorBackground: "#0d1519"
    readonly property color colorBackgroundAccent: "#14292b"
    readonly property color colorSurface: "#233c3c"
    readonly property color colorSurfaceAlt: "#19262d"
    readonly property color colorSurfaceMuted: "#19252b"
    readonly property color colorBorder: "#344a4b"
    readonly property color colorAccent: "#bdedc7"
    readonly property color colorAccentText: "#12241a"
    readonly property color colorAccentTextAlt: "#10241b"
    readonly property color colorTextPrimary: "#f1f3e9"
    readonly property color colorTextSecondary: "#91a7ac"
    readonly property color colorTextBody: "#b3c8c8"
    readonly property color colorTextMuted: "#82999f"
    readonly property color colorScrim: "#000000"

    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 16
    readonly property int spacingLg: 24
    readonly property int spacingXl: 32
    readonly property int spacingXxl: 48

    // Extraits fidèles (mêmes valeurs qu'avant ce refactoring) pour les
    // rythmes qui ne tombent pas exactement sur l'échelle 4px ci-dessus.
    // Nommés par usage plutôt que forcés sur l'échelle, pour ne pas changer
    // silencieusement la mise en page (aucun pixel ne bouge).
    readonly property int spacingPageGutter: 52
    readonly property int spacingSectionGap: 30
    readonly property int spacingTabsGap: 12
    readonly property int spacingTitleGap: 10
    readonly property int spacingCardContent: 14

    readonly property int radiusControl: 8
    readonly property int radiusCard: 26
    readonly property int radiusPill: 23

    readonly property int motionFast: 120
    readonly property int motionOverlay: 180

    // Typographie — tailles extraites telles quelles de Main.qml/QuickMenu.qml.
    readonly property int typeDisplay: 42
    readonly property int typeHeading: 34
    readonly property int typeBrand: 22
    readonly property int typeBrandMark: 25
    readonly property int typeLabel: 17
    readonly property int typeBody: 16
    readonly property int typeMessage: 15
    readonly property int typeFooter: 14
    readonly property int typeBadge: 13
    readonly property int typeMenuEntry: 18
}
