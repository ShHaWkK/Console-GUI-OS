# Navigation UI

Statut : proposition v0.1 à partir de l'inventaire des maquettes, 17 septembre 2026.
Complète docs/ui-analysis.md. Répond à CLAUDE.md section 5 (« identifier la
navigation ») et prépare la FocusManager/NavigationStack de la section 25.

## 1. Graphe de navigation global

```text
Boot screen
   │
   ▼
Sélection de profil (boot screen "Welcome")  ──►  Login (si compte requis)
   │
   ▼
Home ──────────────────────────────────────────────────────────┐
   │  Accept sur une jaquette                                   │ Home (bouton Menu)
   ▼                                                             ▼
Game Detail (TODO — absent des maquettes, à clarifier)     Quick Menu (overlay)
   │ Start                                                       │
   ▼                                                        ┌────┼────────────┬───────────┬──────────────┐
Hello Console / jeu en cours                             Home  Achievements Friends   Notifications   Library
                                                                                              │
Home (Menu ▸ Library) ──► Library (grille) ──► menu contextuel jaquette ──► Game Detail/Launch
   │
   ├──► Settings (Menu ▸ Settings ou raccourci système)
   │        ├─ General ── Display settings / Themes / Parental control
   │        ├─ Account ── Users / Link to social media
   │        ├─ System ── Language & location / Date & time / Error history / Data management
   │        ├─ Devices ── Controller / Test input devices / Mouse / Keyboard / Controller mapping
   │        └─ Preferences ── Notifications / Capture & share
   │
   ├──► Profile (avatar Home) ──► Edit profile / User settings
   │        └─ sous-onglets : Friends (liste/recherche/demandes envoyées-reçues), Activity, Game stats, Messages
   │
   ├──► Notifications (icône cloche Home) ──► liste persistante (toasts transitoires en overlay séparé)
   │
   ├──► Messages (Profile ▸ Messages ou Quick Menu) ──► Conversation ──► Clavier virtuel (overlay)
   │
   └──► Album (Quick Menu ▸ Capture) ──► Galerie ──► type de média

Overlay de capture (déclenché en jeu, hors flux Home) ──► choix (screenshot/vidéo) ──► confirmation
```

## 2. Règles de navigation observées

- **Back** ramène systématiquement à l'écran parent immédiat (jamais à Home
  directement depuis un sous-écran profond), cohérent avec l'action sémantique
  `Back` de CLAUDE.md section 24.
- **Menu (bouton Home manette)** ouvre toujours le Quick Menu en overlay
  au-dessus de l'écran courant, y compris pendant un jeu — jamais de
  reconstruction de la page sous-jacente (CLAUDE.md section 27).
- **Onglets horizontaux** (Quick Menu, header Profile) se parcourent avec
  LB/RB — mapping déjà prévu en section 24 du prompt maître.
- **Settings** utilise une navigation à deux niveaux fixes (catégorie →
  sous-écran) sans niveau supplémentaire ; aucun sous-écran de Settings ne
  mène à un autre sous-écran de Settings.
- **Library → jaquette** ouvre un menu contextuel (`library 1-5 menu.png`)
  avant toute action destructive (désinstaller, etc.), pas d'action directe
  au premier Accept sauf lancement.

## 3. Ordre d'implémentation recommandé

Aligné sur CLAUDE.md sections 26 et 63 (« First Playable ») et sur l'état
réel du code :

```text
1. Boot → Home → Library → Game Detail → Hello Console → Start → Stop → retour Library   [IMPLÉMENTÉ]
2. Settings root + sous-écrans General/Account/System/Devices/Preferences   [IMPLÉMENTÉ, contenu honnête sans réglage simulé]
3. Quick Menu overlay   [IMPLÉMENTÉ]
4. Profile / Friends / Messages / Notifications / Album (TODO, non prioritaire au MVP)
```

## 4. Game Detail — IMPLEMENTED (version minimale, 17 septembre 2026)

Le prompt maître (section 26) place un écran « Game Detail » entre Library et
Hello Console, mais aucune maquette dédiée ne porte ce nom. `library 1-5
menu.png` (menu contextuel sur une jaquette) était le candidat le plus proche
et sert de référence à ce qui a été implémenté.

Version minimale retenue (voir ADR-007 dans `.ai/DECISIONS.md`) : en
Bibliothèque, un premier Entrée sur un jeu ouvre un état de confirmation
(badge « CONFIRMER », hint « Entrée Lancer / Échap Retour à la
bibliothèque ») plutôt que de lancer immédiatement ; un second Entrée
confirme. Sur Home, Entrée lance toujours directement (pas d'étape
intermédiaire, cohérent avec le hint « A Start » de la maquette Home).

Volontairement **pas** implémenté, pour rester honnête (CLAUDE.md section
60) : pas d'actions « Désinstaller » ou « Favoris » dans ce menu, puisque
aucun service ne les porte encore côté backend (le Game Manager n'expose que
`ListGames`/`Launch`/`Stop`/`Status`). Les ajouter maintenant aurait signifié
des boutons qui ne font rien. À étendre quand ces capacités existeront
réellement côté `services/game-manager`.
