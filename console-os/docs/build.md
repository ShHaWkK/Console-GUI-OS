# Build

Statut : 17 septembre 2026. Répond à CLAUDE.md section 38. Les scripts
`bootstrap.sh`/`build.sh`/`test.sh`/`run-dev.sh` visés par cette section
n'existent pas encore sous ces noms exacts — le dépôt fournit aujourd'hui
`system/scripts/dev.sh` (deps/build/test/run) et `system/scripts/run-dev.sh`,
qui couvrent le même besoin. Ne pas dupliquer un second jeu de scripts sans
raison ; ce document décrit ce qui existe réellement.

## Ce qui existe (IMPLEMENTED)

```bash
bash system/scripts/dev.sh deps build test
bash system/scripts/dev.sh run
bash system/scripts/dev.sh deps-session gamescope
```

Équivalent manuel documenté dans `console-os/README.md` :

```bash
sudo pacman -S --needed base-devel cmake qt6-base qt6-declarative qt6-tools dbus python
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

Dernière exécution réelle connue : Ubuntu 24.04 x86_64, GCC 13.3, Qt 6.8.3,
CMake 4.4.3, 15 septembre 2026 (voir `docs/validation.md`). Résultat : build
réussi, 2 suites CTest passées (manifest, manager), 1 suite ignorée
(intégration D-Bus, restrictions root/socket).

## Build dans cette session de travail — PASS (depuis le 17 septembre 2026)

Environnement : Windows 11 avec WSL2 (Ubuntu 24.04). La toolchain
(`build-essential cmake qt6-base-dev qt6-declarative-dev libdbus-1-dev`) a été
installée par l'utilisateur dans WSL le 17 septembre 2026, avec confirmation
explicite avant exécution (installation système non triviale).

Commandes réellement utilisées, depuis PowerShell/Git Bash (le dépôt reste sur
le disque Windows, monté dans WSL sous `/mnt/c/...`) :

```bash
wsl -e bash -lc "cd /mnt/c/Dossier_GitHub/Console-GUI-OS/console-os && cmake -S . -B build-wsl && cmake --build build-wsl -j\$(nproc)"
wsl -e bash -lc "cd /mnt/c/Dossier_GitHub/Console-GUI-OS/console-os && ctest --test-dir build-wsl --output-on-failure"
```

Résultat vérifié le 17 septembre 2026 : GCC 13.3.0, CMake 3.28.3, Qt 6.4.2.
Build réussi (seuls des warnings « clock skew » inoffensifs dus au montage
`/mnt/c`). **4/4 suites CTest PASS** : `manifest`, `manager`, `integration`
(recette D-Bus interprocessus réelle, contre le vrai daemon `game-manager`,
utilisateur non-root — premier succès connu de cette suite, résout ISSUE-002)
et `qml-smoke` (nouveau, smoke test QML `tests/qml_smoke.py` désormais
enregistré dans CTest, SKIP proprement si PySide6 n'est pas installé — voir
`.ai/ISSUES.md` ISSUE-004 pour un bug de flakiness trouvé et corrigé dans ce
test). Détail dans `.ai/STATUS.md` et
`build-wsl/Testing/Temporary/LastTest.log` (répertoire de build local, non
versionné — ajouté à `.gitignore`).

PySide6 (nécessaire pour `qml-smoke`) a été installé dans WSL en espace
utilisateur, sans toucher au système : `pip3 install --user
--break-system-packages pyside6-essentials`. Sans PySide6, `qml-smoke` est
SKIP (pas d'échec) ; c'est le comportement attendu pour un environnement qui
n'en a pas besoin (ex. CI serveur sans QML à vérifier visuellement).

Non couvert par ce build WSL : rendu graphique réel (pas de serveur Wayland
dans WSL, seul le binaire `console-shell` a été compilé et lié, pas affiché),
et bien sûr le boot Arch/Gamescope embedded matériel — voir `bringup.md`.

## CI (TODO)

CLAUDE.md section 40 demande une CI x86_64 et aarch64 exécutant au minimum
`cargo fmt --check` / `cargo clippy` / `cargo test` (une fois du code Rust
introduit — aucun composant Rust n'existe encore dans ce dépôt, tout est
C++/Qt pour l'instant), le build Qt et la validation de manifest. Aucun
fichier de CI n'existe actuellement dans le dépôt (`.github/workflows/` ou
équivalent absent) — à créer lors d'une tâche dédiée, pas silencieusement ici.
