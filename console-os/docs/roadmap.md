# Roadmap et critères de sortie

Chaque étape doit être validée avant d'élargir les privilèges ou les sources de jeux.

| Phase | Livrable | Critère de sortie |
|---|---|---|
| 0 | Architecture, menaces, monorepo, décisions | Frontières UI/service/runtime documentées et périmètre validable |
| 1 | Shell Qt/QML, catalogue local, Hello Console, session exemple | Build Arch ; clavier et manette réelle ; boot dédié ; lancement/retour après sortie/crash |
| 2 | Game Manager et schéma stabilisés | Tests d'erreurs, détection, cycle de vie et état persistant ; cgroup par jeu |
| 3 | .gamepkg, installateur, signatures | Rejet packages malformés/non autorisés ; installation atomique ; coupure simulée |
| 4 | CLI locale + SDK natif | build → package → install → launch → logs → stop automatisé |
| 5 | Developer Mode et déploiement distant | Appairage TLS, révocation, séparation dev/Retail et contrôle d'accès testés |
| 6 | Sandbox renforcée et API de jeux | FS/IPC/réseau interdits par défaut, permissions minimales, tests GPU/audio/input |
| 7 | Updaters jeux et système | Signatures, rollback, échec boot, coupure et migration données testés |

La numérotation ne reporte pas toute la sécurité en phase 6 : validation,
absence de root et pas d'accès distant sont appliqués dès le prototype. La
sandbox minimale doit précéder l'ouverture aux packages tiers, même si cela
oblige à avancer une partie de la phase 6.

## État du lot livré

Code fourni : Home/Library/Settings fullscreen ; clavier ; point d'entrée
sémantique pour contrôleurs ; service D-Bus séparé ; manifests stricts ; lancement,
arrêt et erreurs ; app Hello Console ; tests et scripts ; configuration greetd exemple.

TODO phase 1 : backend manette physique SDL3 (D-pad/sticks/deadzone/hotplug),
bouton Home global, mesures graphiques et validation Arch depuis un boot réel.
L'état des vérifications effectivement exécutées est dans validation.md.

## Backlog produit au-delà de cette tranche

- Identité de démarrage, connexion, profils, verrouillage réel et reprise.
- Favoris, récents persistants, catégories, recherche, jaquettes.
- Réseau Ethernet/Wi-Fi, Bluetooth, audio, vidéo, stockage, manettes.
- Téléchargements avec reprise, quota, notifications, mises à jour de jeux.
- Capture via compositor/portail autorisé, vidéos plus tard.
- Veille, extinction, reboot via logind et règles polkit minimales.
- SDK stable, API utilisateur/sauvegardes/notifications ; achievements et overlay plus tard.
- Export moteurs testés, puis compatibilité Wine/Proton optionnelle.
- Installer Archiso, récupération, provisioning des clés et stratégie Secure Boot.

Pas de délai global fiable sans matériel cible, périmètre runtime et équipe.
Le prochain jalon utile est la recette matérielle de la phase 1, pas un magasin.
