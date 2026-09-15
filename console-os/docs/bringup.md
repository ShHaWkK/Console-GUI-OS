# Recette Arch et session console

Objectif : prouver la chaîne boot → session → shell → jeu → retour shell sur
un matériel dédié. Les exemples livrés ne sont pas automatiquement activés.

## 1. Préparer la machine

Installer Arch x86_64 avec une session utilisateur normale, pilotes GPU adaptés,
Wayland, audio et entrée fonctionnels. Pour les essais embedded, installer
gamescope et greetd depuis les dépôts Arch. Vérifier l'accès DRM/render et seat
via logind ; ne pas lancer Gamescope en root pour contourner un problème d'accès.

Construire et exécuter les tests du README. La recette D-Bus exige un utilisateur
non root et un environnement autorisant les sockets Unix. Le test QML optionnel
utilise PySide6 et se lance avec :

```bash
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software python tests/qml_smoke.py
```

Le test QML utilise une fixture de données. Il ne valide pas le service réel.

## 2. Session imbriquée

Depuis le bureau de développement, après compilation :

```bash
CONSOLE_BIN_DIR="$PWD/build/bin" CONSOLE_CATALOG="$PWD/build/catalog" \
  gamescope --expose-wayland -- dbus-run-session -- "$PWD/system/scripts/console-session"
```

Vérifier le backend Qt Wayland sur la cible. Le manager transmet WAYLAND_DISPLAY
mais pas une liste arbitraire de variables d'environnement de développement.
Qt doit être installé sur la machine cible, pas seulement copié depuis un SDK.

## 3. Installation locale et boot dédié

Après succès des essais en fenêtre, sur une machine de laboratoire uniquement :

```bash
sudo cmake --install build --prefix /usr/local
```

Cette commande installe uniquement les programmes, les scripts et Hello Console.
Elle n'écrase pas /etc/greetd/config.toml et n'active aucun service.

Préparer un compte `console` sans sudo et sans accès SSH. Adapter
system/config/greetd.toml.example avec les chemins et noms réels. L'initial_session
ouvre automatiquement ce compte au boot ; ce n'est ni une authentification de
profil joueur ni un verrouillage. Le greeter de récupération demande ensuite une
authentification si la session se ferme. Conserver un TTY d'administration et une
sauvegarde de la configuration précédente avant d'activer greetd à la place de
l'éventuel display manager existant. Ne pas en lancer deux sur le même VT.

greetd doit ouvrir une vraie session PAM/logind avec XDG_RUNTIME_DIR. Gamescope
est alors lancé sur DRM/KMS depuis le VT, et non imbriqué dans un autre bureau.
Le superviseur reprend les variables du compositor. Le script est volontairement
petit ; reprise automatique bornée après crash et écran de récupération restent TODO.

## 4. Critères de recette

- Boot sans GNOME/KDE ; aucune demande de privilège dans l'interface.
- Home/Library/Settings accessibles au clavier en 720p et 1080p, focus visible.
- Hello Console s'ouvre, reçoit le clavier et rend la main après Échap.
- Sortie normale, crash, exécutable manquant et service arrêté : UI récupérable.
- Manifests invalides rejetés avec erreur exploitable.
- Absence de variable LD_PRELOAD transmise, chemins sauvegardes par jeu.
- Mesurer démarrage, RAM/PSS, frametimes ; pas de promesse avant mesures.
- TODO : manette USB/Bluetooth, hotplug, deadzone, bouton Home global.
- TODO : écran débranché, son HDMI, veille/reprise, GPU Intel/AMD/NVIDIA.

La phase 1 n'est terminée qu'après cette recette et l'ajout du backend manette.
Un rendu logiciel hors écran ou un build réussi ne suffit pas à la déclarer finie.
