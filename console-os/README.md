# Console OS

Prototype de console de jeux Linux basee sur Arch Linux. Le but est de construire
progressivement une plateforme console originale, separee entre un systeme
utilisateur et un DevKit, sans reproduire les interfaces ou technologies
proprietaires des consoles commerciales.

## Etat actuel

Ce depot contient la Phase 0 et une premiere tranche de Phase 1 :

- documentation d'architecture, securite, roadmap, DevKit et bring-up Arch ;
- shell fullscreen Qt 6 / QML avec Home, Library et Settings ;
- navigation clavier et point d'entree semantique pour une future manette ;
- Game Manager minimal expose en D-Bus de session ;
- lecture stricte des manifests `game.json` ;
- lancement d'une application Linux native depuis un catalogue local ;
- application de demonstration `Hello Console` ;
- logs JSON sur stderr ;
- tests unitaires manifest/manager et recette D-Bus.

Ce n'est pas encore une image Retail, un launcher securise pour jeux tiers, un
SDK distribuable ou un systeme avec sandbox forte.

## Technologies retenues

- Arch Linux x86_64 comme base cible.
- systemd, greetd et logind pour la session dediee.
- Gamescope comme compositor cible pour la session jeu.
- Qt 6 / QML pour l'interface fullscreen.
- C++20 pour le prototype shell/service.
- D-Bus de session pour l'IPC interne initial.
- CMake / CTest pour la construction et les tests.

Rust reste recommande pour les futurs composants sensibles : packaging,
verification cryptographique et updater.

## Construire

Le script de developpement automatise les commandes courantes sur Arch :

```bash
bash system/scripts/dev.sh deps build test
```

Equivalent manuel :

```bash
sudo pacman -S --needed base-devel cmake qt6-base qt6-declarative qt6-tools dbus python
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

Le build prepare aussi un catalogue local :

```text
build/catalog/org.consoleos.hello/
```

## Lancer en developpement

Depuis une session graphique Linux avec D-Bus disponible :

```bash
CONSOLE_BIN_DIR="$PWD/build/bin" CONSOLE_CATALOG="$PWD/build/catalog" \
  dbus-run-session -- system/scripts/console-session --windowed
```

Ou via le script :

```bash
bash system/scripts/dev.sh run
```

Pour une session cible avec Gamescope et greetd, suivre `docs/bringup.md`.
Le script peut aussi installer les dependances optionnelles et lancer un essai
imbrique :

```bash
bash system/scripts/dev.sh deps-session gamescope
```

## Arborescence

```text
console-os/
  cli/consolectl/        futur outil DevKit
  core/                  manifest et logs partages
  docs/                  architecture, securite, roadmap, bring-up
  examples/hello-console app native de demonstration
  packaging/             schema manifest et futur .gamepkg
  sdk/                   emplacement du futur SDK
  services/game-manager/ service D-Bus de gestion des jeux
  shell/                 interface console Qt/QML
  system/                scripts et exemples de configuration systeme
  tests/                 tests unitaires et integration D-Bus
```

## Limites importantes

Le MVP organise les donnees par jeu, mais n'isole pas encore les processus. Les
jeux lances partagent toujours l'UID de session. Ne lancer que des binaires de
confiance jusqu'aux phases packaging, signatures, cgroups et sandbox.

Les modes Retail/Developer, le deploiement distant, les mises a jour atomiques,
le support manette physique complet et l'ISO installable sont documentes mais
marques TODO.
