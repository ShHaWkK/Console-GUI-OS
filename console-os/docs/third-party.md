# Projets tiers étudiés

Statut : 17 septembre 2026. Répond à CLAUDE.md section 12. Aucune de ces
dépendances n'est encore intégrée au build actuel (CMakeLists.txt ne lie que
Qt6). Ce document sert de base de décision, pas d'inventaire de licences déjà
redistribuées.

## TIGR — API 2D

- **Nom** : TIGR (Tiny Graphics Library)
- **Repository** : https://github.com/erkkah/tigr
- **Licence** : Domaine public / Unlicense (à reconfirmer sur le dépôt au moment de l'intégration — non vérifié ici faute d'accès réseau dans cette session, NOT TESTED)
- **Rôle envisagé** : backend bas niveau possible pour la future Console 2D API (CLAUDE.md section 13)
- **Intérêt** : bibliothèque C minimaliste, single-header-friendly, primitives bitmap/sprites/fonts/input, pas de dépendances lourdes
- **Limitations** : pas de compositor natif ni de gestion de fenêtre orientée console ; support Vulkan absent (OpenGL/DirectX/Metal selon plateforme) ; à vérifier si le backend Linux utilise GLFW/X11 ou peut être porté proprement sur Wayland/Gamescope
- **Compatibilité ARM64** : NOT TESTED. Code C portable a priori, mais aucun build croisé n'a été tenté dans ce dépôt à ce jour.
- **Utilisation actuelle** : aucune (non intégré)
- **Utilisation prévue** : backend initial de la future `Console 2D API` (Game → Public Console SDK → Console 2D API → 2D Backend → TIGR → Linux/GPU), jamais exposé directement aux développeurs de jeux (CLAUDE.md section 13)
- **Modifications éventuelles** : portage backend Linux/Wayland si le backend par défaut ne convient pas ; à documenter dans un ADR si cela arrive
- **Risques sécurité** : surface d'attaque limitée (bibliothèque graphique locale), à auditer avant d'accepter des assets/fonts non fiables de jeux tiers
- **Risques licence** : faibles si Unlicense confirmée ; à revalider avant toute redistribution binaire

## Gamescope

- **Nom** : Gamescope
- **Repository** : https://github.com/ValveSoftware/gamescope
- **Licence** : BSD-2-Clause (à reconfirmer sur le dépôt au moment de l'intégration, NOT TESTED dans cette session)
- **Rôle envisagé** : compositor Wayland de la session console (CLAUDE.md section 14, déjà retenu dans docs/architecture.md section 2)
- **Intérêt** : conçu pour les sessions de jeu, support nested/embedded, frame pacing, intégration Vulkan/DRM-KMS
- **Limitations** : dépendance à des pilotes GPU Linux récents ; comportement multi-fenêtres à valider ; maintenu par Valve donc évolutions hors de notre contrôle
- **Compatibilité ARM64** : NOT TESTED dans ce dépôt. Gamescope est utilisé sur Steam Deck (x86_64) ; un support ARM64 pour le cloud gaming AWS Graviton reste à valider avant la phase 8.
- **Utilisation actuelle** : recette documentée dans `docs/bringup.md` (nested mode), jamais exécutée avec succès dans un environnement de vérification de cette session (pas de GPU/Wayland disponible sous Windows/WSL sans configuration supplémentaire)
- **Utilisation prévue** : compositor de production de la console-session (systemd → console-session → Wayland → Gamescope → Console Shell)
- **Modifications éventuelles** : aucune prévue, utilisation en boîte noire via ses options CLI
- **Risques sécurité** : exécute avec accès DRM/seat via logind ; ne jamais lancer en root (déjà respecté par docs/bringup.md et docs/security.md)
- **Risques licence** : faibles (BSD-2-Clause, permissive)

## wlroots

- **Nom** : wlroots
- **Repository** : https://gitlab.freedesktop.org/wlroots/wlroots
- **Licence** : MIT (à reconfirmer, NOT TESTED)
- **Rôle envisagé** : bibliothèque pour écrire un compositor Wayland personnalisé (CLAUDE.md section 15)
- **Intérêt** : base standard de nombreux compositors Linux, évite de réimplémenter le protocole Wayland bas niveau
- **Limitations** : nécessite d'écrire et maintenir un compositor complet (DRM, input, focus, protocoles) — un projet à part entière
- **Compatibilité ARM64** : NOT TESTED
- **Utilisation actuelle** : aucune
- **Utilisation prévue** : aucune tant que Gamescope répond au besoin (docs/architecture.md section 2 : « rejeté au MVP »). À réévaluer uniquement si une limitation réelle de Gamescope est démontrée.
- **Modifications éventuelles** : sans objet
- **Risques sécurité** : sans objet (non utilisé)
- **Risques licence** : faibles a priori (MIT), à confirmer si utilisé un jour

## bubblewrap

- **Nom** : bubblewrap (bwrap)
- **Repository** : https://github.com/containers/bubblewrap
- **Licence** : LGPL-2.1-or-later (à reconfirmer, NOT TESTED)
- **Rôle envisagé** : sandboxing des processus jeu (CLAUDE.md section 16, phase 6 de la roadmap)
- **Intérêt** : namespaces mount/PID/user/IPC, intégration seccomp, pas de daemon privilégié requis en continu, largement utilisé (Flatpak)
- **Limitations** : ne fournit qu'un mécanisme — la sécurité réelle dépend du profil de sandbox construit (montages, seccomp, capabilities) ; n'isole pas le GPU/audio par défaut
- **Compatibilité ARM64** : a priori bonne (utilisé par Flatpak sur ARM64), NOT TESTED dans ce dépôt
- **Utilisation actuelle** : aucune — le Game Manager actuel lance les jeux avec l'UID de session, sans namespace (documenté comme limite connue dans docs/security.md)
- **Utilisation prévue** : sandbox par jeu en phase 6, sans réécrire le Game Manager (l'architecture actuelle du lancement de processus doit rester compatible avec un wrapping bubblewrap ultérieur — point de vigilance pour `services/game-manager/manager.cpp`)
- **Modifications éventuelles** : aucune prévue, utilisation via CLI/exec
- **Risques sécurité** : mal configuré, un profil bubblewrap donne un faux sentiment de sécurité ; nécessite des tests dédiés (traversal, symlinks, liens durs — déjà listés dans docs/security.md)
- **Risques licence** : LGPL sur la bibliothèque liée par le binaire `bwrap` lui-même ; utilisation en sous-processus externe (pas de liaison statique) limite l'impact sur la licence du reste du code

## Note générale sur la vérification

Les licences ci-dessus n'ont pas été revérifiées sur les dépôts sources dans
cette session (pas d'accès réseau confirmé/exercé ici). Avant toute
intégration réelle en phase ultérieure, revalider licence et version exacte
sur le dépôt source au moment du commit d'intégration, pas seulement ici.
