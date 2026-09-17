# Project Status

Last update:
2026-09-17 14:30

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
- Settings avec sous-navigation réelle par catégorie (General/Account/System/Devices/Preferences), pilules cliquables et navigables ←/→, contenu honnête (décrit l'état réel — souvent « non implémenté » — jamais un contrôle simulé qui ne ferait rien) — vérifié par capture d'écran hors-écran et par `tests/qml_smoke.py`
- Game Detail minimal (`shell/Main.qml`, `showDetail`) : en Bibliothèque, confirmation à deux temps avant de lancer un jeu (Entrée ouvre le détail, Entrée confirme) ; Home garde le lancement direct. Back à deux niveaux (ferme le détail, puis quitte la Bibliothèque). Voir ADR-007 dans `.ai/DECISIONS.md`
- Clavier virtuel (`shell/VirtualKeyboard.qml`) : grille QWERTY réellement fonctionnelle (taper, ⌫, espace, fermeture), overlay avec focus transféré/restauré comme Quick Menu, intégré à un vrai point d'usage (Settings ▸ Devices, « Entrée pour tester ») plutôt que laissé sans consommateur — vérifié par capture d'écran et par `tests/qml_smoke.py` (saisie, suppression et fermeture via la grille, pas seulement l'ouverture)
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

## Not tested

- Boot Arch dédié, greetd, Gamescope embedded (nécessite matériel/GPU réel, hors de portée de WSL)
- ARM64 (aucun build ARM64 tenté à ce jour)
- AWS
- Manette physique réelle
- Rendu graphique réel du shell (WSL sans serveur graphique Wayland/X — seul le build/CLI a été vérifié, pas l'affichage)

## Current build

**PASS.** Rejoué le 2026-09-17 dans WSL2 Ubuntu 24.04 (GCC 13.3.0, CMake 3.28.3, Qt 6.4.2) après ajout du clavier virtuel. Compilation complète sans erreur (seuls warnings "clock skew" inoffensifs liés au montage /mnt/c).

## Current tests

**4/4 suites CTest PASS** (plusieurs exécutions consécutives confirmées stables) : manifest (22/22), manager (3/3), integration (D-Bus réel), qml-smoke (couvre maintenant aussi une vraie saisie au clavier virtuel : taper deux lettres, supprimer via la touche ⌫ de la grille, fermer via la touche OK de la grille). Détail dans `build-wsl/Testing/Temporary/LastTest.log`.

**Vérification visuelle réelle** (pas supposée) : capture d'écran hors-écran du clavier virtuel ouvert avec du texte réellement saisi ("qwe") affiché en direct. Mise en page propre, pas de chevauchement.

**Bug trouvé pendant l'écriture du test lui-même** (pas dans le produit) : ma première version du test naviguait la grille du clavier en ligne droite (uniquement ←/→) pour atteindre la touche ⌫, qui est en réalité sur une autre ligne — l'assertion a échoué de façon reproductible (4/4 tentatives), révélant l'erreur de navigation du test, pas un bug du composant. Corrigé en ajoutant les appuis ↓ manquants.

**Bugs de robustesse trouvés et corrigés dans les tours précédents** : flakiness non déterministe du smoke test QML (ISSUE-004), chevauchement de mise en page Settings (ISSUE-006) — voir `.ai/ISSUES.md`.

## Last completed task

Clavier virtuel QML fonctionnel (`shell/VirtualKeyboard.qml`), intégré à un vrai point d'usage dans Settings ▸ Devices plutôt que laissé sans consommateur. Build + 4 suites CTest + capture d'écran, tout vérifié réellement dans WSL2.

## Current task

L'utilisateur a demandé de continuer sur : clavier virtuel (FAIT ci-dessus), profils/login/boot, ARM64, Gamescope réel, AWS. Gamescope réel et AWS restent explicitement hors de portée de cette session (pas de GPU/Wayland dans WSL2 ; AWS nécessite des identifiants et engage des coûts réels que je n'ai pas l'autorisation d'engager sans confirmation explicite). Prochaine étape réaliste : vérifier la faisabilité d'un cross-build ARM64 (juste une vérification de disponibilité des paquets, avant toute installation lourde), puis profils/login/boot avec des assets honnêtes (pas de placeholder qui prétend être un vrai compte).

## Note environnement

Ce dépôt cible Arch Linux x86_64 (dev) puis Linux ARM64 (cloud). La session de travail s'exécute sur Windows 11 avec WSL2 (Ubuntu 24.04). La toolchain (build-essential, cmake, qt6-base-dev, qt6-declarative-dev, libdbus-1-dev) a été installée dans WSL par l'utilisateur le 2026-09-17, ce qui permet désormais de compiler et tester réellement le dépôt depuis cette session (build dans `console-os/build-wsl/`, à ne pas committer). Le rendu graphique réel (Wayland/Gamescope) reste hors de portée de WSL et nécessite du matériel Arch dédié (voir docs/bringup.md).
