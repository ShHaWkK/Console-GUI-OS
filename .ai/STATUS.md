# Project Status

Last update:
2026-09-17 13:00

## Current phase

PHASE 1 — Console Prototype (fin de première tranche)

## Overall progress

Phase 0: 100%
Phase 1: 45%
Phase 2: 15% (manifest strict + lifecycle basique déjà livrés dans le Game Manager C++)
Phase 3: 0%
Phase 4: 5% (arborescence `cli/consolectl/`, aucune commande implémentée)
Phase 5: 0%
Phase 6: 0% (menace documentée dans docs/security.md, aucun code)
Phase 7: 0%
Phase 8: 0%
Phase 9: 0%

## Working (IMPLEMENTED, vérifié par build/tests sur Ubuntu 24.04 x86_64, voir console-os/docs/validation.md)

- Repository CMake/C++20 + Qt6/QML (`console-os/`)
- Shell Qt/QML fullscreen : Home, Library, Settings root, navigation clavier (`shell/Main.qml`, `shell/backend.*`)
- Design system (`shell/Theme.qml`) : couleurs, spacing, rayons, typographie et durées d'animation extraits fidèlement (mêmes valeurs, zéro changement visuel) et consommés dans Main.qml/QuickMenu.qml — plus aucune valeur littérale de style dupliquée dans ces deux fichiers
- Transitions fluides réelles : pilules d'onglet et carte de contenu animées (`Behavior on color/border`), pulse de contenu au changement de page, panneau Quick Menu qui glisse à l'ouverture/fermeture (`anchors.leftMargin` animé, easing OutCubic)
- Quick Menu overlay (`shell/QuickMenu.qml`) : 4 entrées réellement câblées (Reprendre/Accueil/Bibliothèque/Réglages), état de la page préservé derrière, focus transféré puis restauré — vérifié par `tests/qml_smoke.py`, maintenant **intégré à CTest** (test `qml-smoke`, SKIP propre si PySide6 absent)
- Point d'entrée `NavigationAction` sémantique (clavier ; manette physique non branchée)
- Game Manager D-Bus (`services/game-manager`) : découverte catalogue, lecture manifest, lancement, arrêt, PID, stdout/stderr
- Parseur + validateur strict de manifest `game.json` (`core/manifest.cpp`) : schema, ID, version, chemins relatifs, anti path-traversal, anti-symlink, taille bornée
- Hello Console (`examples/hello-console`) : manifest + QML natif, testé end-to-end en local (hors D-Bus interprocessus, voir Not tested)
- Tests unitaires manifest (20 cas) et manager (catalogue, double lancement, arrêt, échec exécutable) — QtTest
- Scripts `system/scripts/dev.sh`, `console-session`, `console-graphical-session`
- Documentation : architecture.md, security.md, devkit.md (TODO explicite), roadmap.md, bringup.md, validation.md, packaging/README.md (TODO explicite)

## Partially working

- Abstraction manette : enum sémantique côté shell présent ; aucun backend SDL3/évènementiel branché sur un périphérique physique

## Not working

- Manette physique (aucun backend d'entrée réel)
- Session Gamescope/greetd en production (seule la recette est documentée dans bringup.md, jamais exécutée sur Arch réel)
- Profils/comptes utilisateurs, login, boot screen (aucun code — maquette seulement)
- Clavier virtuel (aucun code — maquette seulement)

## Not tested

- Boot Arch dédié, greetd, Gamescope embedded (nécessite matériel/GPU réel, hors de portée de WSL)
- ARM64 (aucun build ARM64 tenté à ce jour)
- AWS
- Manette physique réelle
- Rendu graphique réel du shell (WSL sans serveur graphique Wayland/X — seul le build/CLI a été vérifié, pas l'affichage)

## Current build

**PASS.** Rejoué le 2026-09-17 dans WSL2 Ubuntu 24.04 (GCC 13.3.0, CMake 3.28.3, Qt 6.4.2) après reconfiguration CMake (nouveau test `qml-smoke`). Compilation complète sans erreur (seuls warnings "clock skew" inoffensifs liés au montage /mnt/c).

## Current tests

**4/4 suites CTest PASS** : manifest (22/22), manager (3/3), integration (D-Bus réel), **qml-smoke (nouveau, intégré cette session)**. Détail dans `build-wsl/Testing/Temporary/LastTest.log`.

Le test `qml-smoke` couvre explicitement le Quick Menu (ouverture, page derrière inchangée, sélection, fermeture, focus restauré). Il est SKIP proprement (pas d'échec) si PySide6 n'est pas installé, comme `integration` l'est déjà pour l'absence de bus D-Bus — voir `CMakeLists.txt` `SKIP_REGULAR_EXPRESSION`.

**Bug de robustesse trouvé et corrigé pendant cette tranche** : le smoke test QML échouait de façon non déterministe (~1 exécution sur 2) avec des `TypeError: Cannot read property ... of null` après son propre PASS, causées par l'ordre non garanti du ramasse-miettes Python en fin de script (le wrapper `backend` pouvait être libéré avant le moteur QML `engine`). Vérifié que **le vrai binaire n'est pas concerné** : `shell/main.cpp` déclare `Backend` avant `QQmlApplicationEngine`, donc le C++ détruit toujours le moteur avant le backend (ordre inverse de construction). Corrigé en reproduisant cet ordre explicitement en fin de script (`tests/qml_smoke.py`) : 6/6 exécutions propres après correction, contre un cas d'échec sur 4 avant.

## Last completed task

Design system complété (spacing/typographie/animations), transitions fluides ajoutées, smoke test QML intégré à CTest, et un vrai bug de flakiness de test trouvé et corrigé (voir ci-dessus). Tout vérifié par build + 4 suites CTest réelles dans WSL2. Voir ADR-005 et ADR-006 dans `.ai/DECISIONS.md`.

## Current task

Revue de robustesse du backend D-Bus (`services/game-manager`) : déjà solide (refus root, double-lancement bloqué, arrêt gracieux SIGTERM→SIGKILL après 3s, environnement enfant allowlist, revalidation du manifest juste avant lancement, rate-limit des logs) — aucun changement de code jugé nécessaire pour l'instant sans bug identifié (voir `.ai/ISSUES.md` pour ce qui reste réellement ouvert). Prochaine tâche : choisir entre sous-écrans Settings ou backend manette physique (`.ai/NEXT.md`).

## Note environnement

Ce dépôt cible Arch Linux x86_64 (dev) puis Linux ARM64 (cloud). La session de travail s'exécute sur Windows 11 avec WSL2 (Ubuntu 24.04). La toolchain (build-essential, cmake, qt6-base-dev, qt6-declarative-dev, libdbus-1-dev) a été installée dans WSL par l'utilisateur le 2026-09-17, ce qui permet désormais de compiler et tester réellement le dépôt depuis cette session (build dans `console-os/build-wsl/`, à ne pas committer). Le rendu graphique réel (Wayland/Gamescope) reste hors de portée de WSL et nécessite du matériel Arch dédié (voir docs/bringup.md).
