# Next Tasks

## Current

[ ] Vérifier la faisabilité d'un cross-build ARM64 (disponibilité des paquets `crossbuild-essential-arm64` / Qt6 multiarch dans WSL, sans installation lourde tant que l'utilisateur n'a pas confirmé) — sortir ARM64 du statut NOT TESTED si possible
[ ] Profils/Login/Boot screen : version honnête avec assets placeholder internes (pas les visuels Valorant/Xbox des maquettes, voir ADR-004), pas de fausse authentification tant qu'aucun user-service n'existe côté backend

## Next

[ ] Écrire un backend manette physique (SDL3 ou évènements evdev) branché sur l'enum NavigationAction déjà présent côté shell, et sur l'action "menu" du Quick Menu (bouton Home manette). NOT TESTABLE avec un vrai périphérique dans cette session (WSL2 sans passthrough USB) — prévoir une validation sur machine Linux avec manette physique avant de considérer la tâche vérifiée.
[ ] Étendre le Game Detail avec Favoris/Désinstaller une fois que le Game Manager exposera réellement ces capacités côté backend (pas avant — voir docs/ui-navigation.md section 4)
[ ] Brancher le clavier virtuel à un vrai champ de saisie utilisateur (recherche Library, renommage de profil) une fois qu'un de ces cas existera réellement

## Later

[ ] Gamescope réel en nested puis embedded sur matériel Arch — **hors de portée de cette session** : pas de GPU/Wayland dans WSL2, nécessite une machine Linux dédiée
[ ] AWS (cloud gaming) — **hors de portée de cette session** : nécessite des identifiants AWS et engage des coûts réels, à ne lancer qu'avec autorisation explicite et un budget défini par l'utilisateur
[ ] Évalué et non retenu pour l'instant : extraction `MenuItem` entre onglets et catégories Settings (styles visuels réellement différents) — voir docs/design-system.md section 4, à reconsidérer si un 3e écran fait émerger un vrai motif commun
