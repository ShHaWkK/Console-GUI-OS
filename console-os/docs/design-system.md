# Design System

Statut : **v0.3 — tokens couleur/spacing/rayons/typographie/animation tous
migrés, overlay Quick Menu avec transitions fluides**, 17 septembre 2026.
Dérivé de docs/ui-analysis.md. Répond à CLAUDE.md section 25 : centraliser
couleurs/typographie/spacing/rayons/dimensions/animations plutôt que de
disperser `font.pixelSize: 37` dans 150 fichiers QML. Identité propre à
Console OS, pas une copie de la charte visuelle des maquettes tierces (voir
ADR-004).

## 1. Principe

Un seul point de vérité QML pour les tokens visuels, partagé par les
composants. **Implémenté** dans `shell/Theme.qml` (pas un `pragma Singleton`
QML — le projet n'utilise pas `qt_add_qml_module`/`qmldir`, juste un `.qrc`
brut ; `Theme` est donc un composant ordinaire instancié une fois dans
`Main.qml` via `Theme { id: theme }` et transmis explicitement aux enfants,
ex. `QuickMenu { theme: theme }`). Documenté comme décision dans
`.ai/DECISIONS.md` ADR-005.

## 2. Tokens

### Couleurs — IMPLEMENTED dans `shell/Theme.qml`

Palette réellement extraite de `Main.qml` (déjà cohérente avant ce
refactoring), pas une palette inventée séparément. Remplace la proposition
neutre v0.1 ci-dessous par les valeurs effectivement utilisées :

| Token QML (`Theme.qml`) | Usage | Valeur |
|---|---|---|
| `colorBackground` | Fond plein écran | `#0d1519` |
| `colorBackgroundAccent` | Halo décoratif coin supérieur droit | `#14292b` |
| `colorSurface` | Carte de contenu Home/Library | `#233c3c` |
| `colorSurfaceAlt` | Carte Settings, panneau Quick Menu | `#19262d` |
| `colorSurfaceMuted` | Pilule d'onglet inactive | `#19252b` |
| `colorBorder` | Bordure carte de contenu | `#344a4b` |
| `colorAccent` | Focus, onglet actif, badge, sélection Quick Menu | `#bdedc7` |
| `colorAccentText` | Texte sur fond `colorAccent` (pilules) | `#12241a` |
| `colorAccentTextAlt` | Texte sur fond `colorAccent` (logo) | `#10241b` |
| `colorTextPrimary` | Titres, contenu principal | `#f1f3e9` |
| `colorTextSecondary` | Sous-titres | `#91a7ac` |
| `colorTextBody` | Texte de description | `#b3c8c8` |
| `colorTextMuted` | Hints clavier/manette | `#82999f` |
| `colorScrim` | Voile derrière un overlay (Quick Menu) | `#000000` à 55% d'opacité |

Une palette « success/warning/danger » sémantique reste à ajouter au moment
où un premier écran en aura réellement besoin (ex. erreurs Settings) —
non ajoutée maintenant pour éviter des tokens inutilisés.

### Typographie — IMPLEMENTED dans `Theme.qml`

Tailles extraites telles quelles (aucun changement visuel) : `typeDisplay`
(42, titre de page), `typeHeading` (34, titre de carte), `typeBrand` (22,
wordmark), `typeBrandMark` (25, monogramme logo), `typeLabel` (17, texte des
pilules/sous-titre), `typeBody` (16), `typeMessage` (15, message de statut),
`typeFooter` (14, hints clavier), `typeBadge` (13, badges NATIVE/SYSTÈME),
`typeMenuEntry` (18, entrées du Quick Menu). Plus aucun `font.pixelSize`
littéral dans `Main.qml`/`QuickMenu.qml`.

Une échelle typographique plus « propre » (multiples réguliers façon
`type.display/title/heading/body/caption`) reste une piste pour un futur
deuxième écran qui n'aurait pas à respecter le pixel exact de l'existant.

### Spacing — IMPLEMENTED dans `Theme.qml`, consommé partout dans Main.qml

`spacingXs..Xxl` (échelle 4px) plus des exceptions nommées fidèles à
l'existant : `spacingPageGutter` (52, marge de page), `spacingSectionGap`
(30, rythme vertical de la page), `spacingTabsGap` (12, entre pilules),
`spacingTitleGap` (10, entre titre et sous-titre), `spacingCardContent` (14,
intérieur de la carte). Toutes les marges/espacements de `Main.qml` passent
maintenant par un token — plus aucun nombre littéral de spacing.

### Rayons et dimensions — IMPLEMENTED pour ce qui est utilisé

| Token | Usage | Valeur |
|---|---|---|
| `radiusPill` | Pilules d'onglet Home/Library/Settings | 23px |
| `radiusCard` | Carte de contenu principale | 26px |
| `radiusControl` | Ligne sélectionnée du Quick Menu | 8px |

Non ajoutés faute d'usage réel actuel : `radius.avatar` (pas encore de
`ProfileAvatar`), `size.cardWidth/cardHeight` (pas encore de `GameCard`),
`size.focusRingWidth`. À ajouter au moment où un écran en a réellement besoin.

### Animation — IMPLEMENTED et étendu

| Token | Usage | Valeur |
|---|---|---|
| `motionFast` | Bordure/couleur de carte et de pilule au focus, pulse de contenu au changement de page, sélection Quick Menu | 120ms |
| `motionOverlay` | Fondu d'opacité et glissement du panneau à l'ouverture/fermeture du Quick Menu (`anchors.leftMargin`, easing OutCubic) | 180ms |

`motion.medium` (transition de page complète façon NavigationStack) reste
une piste future, pas nécessaire tant qu'il n'y a qu'un seul niveau de page.

## 3. Composants (mappés aux écrans de docs/ui-analysis.md section 2)

| Composant QML | Écrans sources | Rôle |
|---|---|---|
| `ConsoleApplication` | — (racine) | Fenêtre fullscreen, thème global, gestion du focus racine |
| `ConsolePage` | Home, Library, Settings, Profile... | Page pleine largeur avec titre + séparateur (motif « barre de titre de section ») |
| `ConsoleOverlay` | Quick Menu, capture, clavier virtuel | Overlay au-dessus de la page courante, focus transféré/restauré (section 27) |
| `NavigationStack` | Toute navigation Back/Accept | Pile de pages, gère le bouton Back sémantique |
| `FocusManager` | Toute navigation manette/clavier | Résolution du focus par direction (Up/Down/Left/Right) |
| `GameCard` | Library, Home | Jaquette + titre, variante « compact » (Home) et « grille » (Library) |
| `GameGrid` | Library, Home | Disposition en grille/rangée de `GameCard` avec défilement |
| `MenuItem` | Settings tuiles, Quick Menu sidebar, menu contextuel Library | Item générique icône + label, état actif/focus |
| `SettingsItem` | Tous les sous-écrans Settings | Ligne de réglage (label + contrôle : toggle/select/slider) |
| `ProfileAvatar` | Boot screen, Home, Notifications, Profile | Avatar circulaire + halo de statut |
| `StatusBar` | Home, Boot screen | Horloge, batterie manette, icônes réglages/notifications |
| `ControllerHint` | Home, Library (bas d'écran) | Libellé bouton manette + action (« A Accept », « + Options ») |
| `NotificationToast` | home-notifications-* | Toast transitoire coin d'écran |
| `ModalDialog` | Overlay capture | Boîte de dialogue centrée avec choix |
| `QuickMenu` **(IMPLEMENTED — `shell/QuickMenu.qml`)** | menu (rapide)/ | Overlay sidebar avec 4 entrées réellement câblées (Reprendre/Accueil/Bibliothèque/Réglages), focus transféré/restauré, page derrière préservée — vérifié par `tests/qml_smoke.py` |
| `VirtualKeyboard` | virtual keyboard/, messages | Clavier QWERTY avec hints manette (LB/RB/LT/Y) |
| `LoadingIndicator` | — (non présent explicitement dans les maquettes, à prévoir) | Indicateur de chargement générique |
| `ErrorDialog` | — (dérivé de ModalDialog) | Erreur bloquante (ex. jeu introuvable) |

## 4. État actuel du code (KEEP / IMPROVE / REFACTOR)

Mise à jour au 17 septembre 2026 :

- **KEEP** : la logique de navigation et le binding D-Bus vers le Game
  Manager (`shell/backend.cpp`) — fonctionnels et testés, jamais modifiés par
  ces refactorings (mêmes actions `left/right/up/down/tab/accept/refresh/back`).
- **FAIT (REFACTOR sans régression)** : couleurs, spacing, rayons et
  typographie de `Main.qml`/`QuickMenu.qml` passent intégralement par
  `theme.*` au lieu de littéraux. Zéro changement visuel voulu (mêmes
  valeurs), vérifié par les 3 suites CTest C++ (inchangées) et le smoke test
  QML (`tests/qml_smoke.py`, maintenant dans CTest en tant que `qml-smoke`).
- **FAIT (fluidité)** : transitions réelles ajoutées (`Behavior on color`,
  glissement du panneau Quick Menu, pulse de contenu au changement de page)
  — voir section Animation ci-dessus.
- **FAIT (nouveau, pas un refactor)** : `QuickMenu.qml` ajouté comme overlay
  additif à côté de `navigation`, sans toucher à sa logique interne. Le
  bouton clavier `Home` a changé de sens (il ouvrait `page = 0` ; il ouvre
  maintenant le Quick Menu, conformément à CLAUDE.md section 24 « Home →
  Quick Menu ») — changement délibéré, documenté ici et dans
  `.ai/DECISIONS.md` ADR-006.
- **RESTE À FAIRE** : `ConsolePage`, `GameCard`, `MenuItem` et les autres
  composants du tableau ci-dessus n'existent pas encore — ils seront extraits
  au moment où un deuxième écran (Settings) en aura réellement besoin, pas
  avant (CLAUDE.md section 57 : ne pas anticiper une abstraction sans un
  deuxième cas d'usage réel).

## 5. Ce qui n'est pas encore fixé

Les valeurs de couleur/typo ci-dessus sont une proposition de travail interne,
pas une charte graphique finale validée par l'utilisateur. Aucune maquette
fournie ne donne de palette précise (la majorité sont des wireframes gris/
blanc/noir sans charte). À valider avec l'utilisateur avant d'industrialiser
au-delà du prototype.
