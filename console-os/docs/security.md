# Sécurité : garanties et limites

## Modèle de menace

Adversaires futurs : jeu malveillant, package piégé, client distant non appairé,
miroir compromis, utilisateur local non autorisé. Un administrateur root ou un
attaquant physique capable de changer le boot reste hors de la garantie MVP.
Une politique Retail robuste nécessitera aussi chaîne de boot et clés protégées.

## Appliqué dans le prototype

- Le manager refuse de tourner comme root.
- API de lancement par ID ; aucun shell, sudo, chemin ou argument arbitraire reçu.
- Manifest borné, champs stricts, chemins relatifs, liens refusés et contenu sous catalogue.
- Environnement enfant reconstruit ; pas d'héritage automatique de LD_PRELOAD,
  LD_LIBRARY_PATH ou de secrets du processus parent.
- Un jeu actif ; erreurs explicites ; journal JSON sur stderr et flux jeu borné.
- Aucun service TCP/SSH, aucune installation, aucun debug distant.

## Non garanti à ce stade

Le jeu partage l'UID et l'accès filesystem du compte de session. Les variables
XDG et CONSOLE_SAVE_PATH organisent les données, elles ne protègent rien.
Un programme hostile pourrait lire les données de cet UID et attaquer ses
processus. Le bus de session n'est pas une frontière contre un autre processus
du même utilisateur. Ne lancer que le Hello Console fourni ou des jeux connus.

Les payloads du prototype ne sont ni signés ni hachés. Validation de chemin et
relecture ne constituent pas une défense contre une modification concurrente
par un attaquant de même UID. Stop ne garantit pas l'arrêt de descendants
détachés. Les logs ne sont pas un journal d'audit inviolable.

## Renforcement prévu

1. Payloads immuables possédés par l'installateur ; validation via descripteurs
   et openat2/RESOLVE_BENEATH, pas de course entre contrôle et utilisation.
2. Unité systemd transitoire par jeu et cgroups v2 : arrêt de tous les descendants,
   limites mémoire/processus/CPU, accounting. Un cgroup n'isole pas le filesystem.
3. bubblewrap : namespaces mount/PID/IPC, runtime en lecture seule, sauvegardes
   propres en écriture, /tmp privé, réseau absent sauf autorisation explicite.
4. Filtrage seccomp adapté à l'ABI, no_new_privs et capabilities vides. bubblewrap
   fournit un mécanisme ; la sécurité dépend du profil construit et testé.
5. Accès limité aux render nodes GPU ; pas de carte DRM de contrôle ; sockets
   Wayland/audio sélectionnés. Ne pas monter tout /dev ou le bus de session.
6. Broker d'API authentifiant le processus/cgroup pour l'ID jeu et l'utilisateur.
   Pas d'identité fournie librement par le jeu. D-Bus proxy filtré si requis.
7. GPU, serveur audio et compositor restent une surface partagée. Xwayland doit
   être isolé par jeu ou écarté pour les jeux non fiables, pas exposé globalement.
8. Journaux d'audit système séparés, rotation et quotas ; jamais de secrets,
   tokens d'appairage ou contenu des sauvegardes dans les journaux.

Les tests sécurité devront couvrir traversal, symlinks, liens durs, bombes de
décompression, signatures invalides, clés révoquées, rejeu métadonnées et appels
DevKit non autorisés. Le rollout Retail reste bloqué jusqu'à ces validations.
