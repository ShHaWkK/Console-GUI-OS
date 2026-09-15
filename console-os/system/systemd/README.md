# Intégration systemd

greetd.service, fourni par Arch, crée la session PAM/logind. Le MVP utilise
console-session à l'intérieur de Gamescope pour transmettre le bon environnement
graphique au Game Manager et au shell. Aucun daemon privilégié maison à activer.

TODO : cible utilisateur console-session.target et unités transitoires par jeu,
avec KillMode=control-group, accounting, limites, arrêt lié à la session et import
explicite de WAYLAND_DISPLAY/XDG_RUNTIME_DIR. Ne pas activer un Game Manager au boot
avant le compositor. Ne pas fournir une unité root lançant le shell graphique.
