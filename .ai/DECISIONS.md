# Architecture Decisions

## ADR-001

Decision:
Use Qt 6/QML for Console Shell.

Reason:
Good embedded Linux support, GPU acceleration and controller-oriented focus handling.

Date:
2026-09-15

Status:
Accepted (implémenté, non remis en cause par l'audit du 2026-09-17)

## ADR-002

Decision:
Utiliser D-Bus de session comme IPC entre le Shell QML et le Game Manager, au lieu d'un socket Unix maison ou de gRPC local.

Reason:
D-Bus est natif sur Linux, s'intègre à Qt, fournit introspection/erreurs/signaux sans framing ni sérialisation à réimplémenter. gRPC local est disproportionné pour trois commandes (launch/stop/status).

Date:
2026-09-15

Status:
Accepted (implémenté dans services/game-manager, exposé en org.consoleos.GameManager1)

## ADR-003

Decision:
Le Game Manager refuse explicitement de s'exécuter en tant que root, et l'API de lancement des jeux prend un ID de catalogue (jamais un chemin ou une commande arbitraire fournie par le frontend).

Reason:
Applique le principe du moindre privilège dès le prototype (CLAUDE.md section 34) plutôt que de reporter la sécurité à la phase 6. Empêche toute injection de commande depuis QML.

Date:
2026-09-15

Status:
Accepted (implémenté et testé — voir core/manifest.cpp, services/game-manager/manager.cpp)

## ADR-004

Decision:
Les maquettes UI fournies (`maquette/`) servent uniquement de référence fonctionnelle et de navigation. Les écrans à haute fidélité qui réutilisent une identité visuelle tierce identifiable (ex. login au branding Valorant, Home au layout et à la mention explicite « Xbox Controller » calqués sur le dashboard Xbox, jaquettes de jeux commerciaux réels) ne seront jamais intégrés tels quels au produit. Le design system (docs/design-system.md) définit une identité propre ; seule l'intention UX (navigation par cartes, quick menu overlay, hiérarchie des réglages) est reprise.

Reason:
CLAUDE.md interdit explicitement la copie d'interfaces propriétaires (Xbox/PlayStation/Nintendo) et impose de ne pas intégrer automatiquement logos/illustrations/marques tierces des maquettes en section 6.

Date:
2026-09-17

Status:
Accepted

## ADR-005

Decision:
`Theme.qml` est un composant QML ordinaire (QtObject), instancié une fois dans `Main.qml` (`Theme { id: theme }`) et transmis explicitement aux enfants (ex. `QuickMenu { theme: theme }`), plutôt qu'un singleton QML (`pragma Singleton` + `qmldir`).

Reason:
Le projet compile les QML via un `.qrc` brut avec `CMAKE_AUTORCC`, sans `qt_add_qml_module` ni module QML nommé. Un vrai singleton `pragma Singleton` nécessite un `qmldir` et un chemin d'import de module, ce qui aurait exigé de migrer toute la chaîne de build QML pour un seul bénéfice cosmétique (éviter de passer `theme` en propriété). Introduire cette migration sans besoin réel aurait contredit CLAUDE.md section 57 (ne pas réécrire ce qui fonctionne sans justification).

Date:
2026-09-17

Status:
Accepted (implémenté dans shell/Theme.qml)

## ADR-006

Decision:
La touche clavier `Home` (développement) ouvre désormais le Quick Menu overlay au lieu de réinitialiser la page courante à Home. Le retour à la page Home via clavier reste possible via `Échap` (action `back`).

Reason:
CLAUDE.md section 24 mappe explicitement le bouton Home manette sur l'ouverture du Quick Menu (« Home → Quick Menu »), distinct de Back. L'ancien comportement (Home clavier = reset vers la page Home) entrait en conflit avec cette sémantique dès qu'un Quick Menu réel a été implémenté. `tests/qml_smoke.py` a été mis à jour pour vérifier le nouveau comportement plutôt que l'ancien.

Date:
2026-09-17

Status:
Accepted (implémenté dans shell/Main.qml, vérifié par tests/qml_smoke.py)

## ADR-007

Decision:
Game Detail minimal : en Bibliothèque, le premier Entrée sur un jeu ouvre un état de confirmation (`showDetail`) au lieu de lancer immédiatement ; un second Entrée confirme le lancement. Sur Home, Entrée lance toujours directement, sans étape intermédiaire. Back (Échap) est à deux niveaux depuis cet état : un premier Échap ferme la confirmation sans quitter la Bibliothèque, un second ramène à Home.

Reason:
CLAUDE.md section 26 place un écran « Game Detail » entre Library et Hello Console dans l'ordre d'implémentation recommandé. Aucune maquette dédiée ne porte ce nom (voir docs/ui-navigation.md section 4), mais `library 1-5 menu.png` montre un menu contextuel avant action sur une jaquette — c'est ce comportement qui est repris ici, sous la forme la plus honnête possible : pas de menu avec des actions fictives (pas d'« Ajouter aux favoris » qui ne ferait rien), seulement une confirmation avant le seul vrai effet de bord disponible (lancer le jeu). Home garde un lancement direct : cohérent avec le hint « A Start » visible dans la maquette home 1.jpg, qui ne montre pas d'étape intermédiaire pour reprendre une partie depuis l'accueil.

Date:
2026-09-17

Status:
Accepted (implémenté dans shell/Main.qml, vérifié par tests/qml_smoke.py et capture d'écran hors-écran)
