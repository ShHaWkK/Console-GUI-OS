# Analyse des maquettes UI

Statut : inventaire et analyse, 17 septembre 2026. Source : `maquette/` à la racine
du dépôt (13 dossiers, 160 fichiers PNG/JPG, fidélité hétérogène — du wireframe
gris au mockup haute fidélité). Ce document répond à CLAUDE.md section 5.

## 1. Inventaire par catégorie

| Dossier | Fichiers | Écrans couverts | Fidélité |
|---|---|---|---|
| boot screen | 13 | Écran de démarrage (fond étoilé, sélection de profil « Welcome ») + doublons d'écrans utilisateurs (settings 2-(account)) | Haute pour boot, basse pour le reste (doublons) |
| login | 1 | Authentification (identifiant/mot de passe) | Haute fidélité, **branding Valorant/Riot Games tiers** |
| home | 3 | Accueil, profil rapide, menu rapide | Haute fidélité, **layout et libellés calqués sur le dashboard Xbox** |
| library | 7 | Grille de jeux, menu contextuel, filtre, favoris | Basse (wireframe) |
| menu (rapide) | 6 | Quick Menu : home, achievements, friends, notifications, library, capture | Basse (wireframe, sidebar + onglets) |
| profile | 41 | Profil, édition profil, réglages utilisateur, amis (liste/recherche/demandes), activité, stats de jeu, messages | Basse à moyenne |
| Account Information (profile) | 7 | Infos de compte, upsell, abonnements | Basse |
| settings | 61 | 5 catégories (General, Account, System, Devices, Preferences) et leurs sous-écrans (affichage, thèmes, contrôle parental, utilisateurs, réseau/langue, date/heure, historique d'erreurs, gestion des données, manette, souris, clavier, mapping manette, notifications, capture & partage) | Basse (wireframe cohérent) |
| notifications | 7 | Centre de notifications + types de toasts (ami connecté, invitation, message, manette connectée, succès) | Basse |
| messages | 4 | Conversation + clavier virtuel intégré | Basse |
| album | 5 | Galerie de captures, types de médias | Basse |
| overlay | 3 | Overlay de capture (choix, screenshot pris, enregistrement vidéo) | Basse |
| virtual keyboard | 2 | Clavier virtuel manette (QWERTY + variante compacte) | Haute fidélité (mockup sombre complet) |

Total : 160 fichiers pour environ **13 familles d'écrans**, correspondant à la
liste attendue en section 5 du prompt maître (boot, login, profils, Home,
Library, Quick Menu, utilisateurs, amis, activités, statistiques, messages,
notifications, album, captures, clavier virtuel, paramètres système/réseau/
contrôleurs/mapping/stockage/affichage/audio/compte/données/préférences). Les
familles **Game Detail** et **stockage/audio dédiés** n'apparaissent pas
explicitement comme écrans séparés — voir section 5.

## 2. Composants communs identifiés

Récurrents dans plusieurs dossiers, donc candidats directs au design system
(docs/design-system.md) plutôt qu'à une réimplémentation par écran :

- **Barre de titre de section** : icône + titre + séparateur horizontal fin (settings, notifications, library, profile). Toujours en haut, alignée à gauche.
- **Sidebar de navigation verticale** : liste de labels empilés avec un label actif souligné/en gras (settings : General/Account/System/Devices/Preferences ; profile : sous-onglets).
- **Barre d'onglets horizontale iconographique** : icônes en ligne avec indicateur actif (souligné) — observée dans le menu rapide et le header du profil (home/friends/notifications/library/capture).
- **Carte (Card)** : rectangle à bordure fine, contenu centré ou jaquette pleine largeur — utilisé pour Library (jaquettes), Settings (tuiles de catégories), Home (jaquettes de jeux). Un seul composant `GameCard`/`MenuItem` générique couvre les deux usages avec des variantes de contenu.
- **Avatar circulaire** : photo de profil ronde avec halo de statut (couleur = présence/activité), utilisé dans boot screen, home, menu rapide, notifications, profile.
- **Liste de notifications/toasts** : ligne avec icône ou avatar à gauche, texte à droite, séparateur horizontal — répété identique entre `notifications/` et `home-notifications-*`.
- **Barre de statut système** : horloge, batterie manette, icône réglages/notifications en haut à droite (home, boot screen).
- **Clavier virtuel** : pavé QWERTY sombre avec indications de boutons manette (LB/RB, LT, Y pour espace) — un seul composant réutilisable pour messages et recherche.
- **Boutons d'action bas d'écran avec hint manette** : « A Start », « + Options » — correspond directement au composant `ControllerHint` prévu en section 25 du prompt maître.

## 3. Layouts identifiés

- **Layout plein écran à fond illustré + contenu superposé** (boot, home, login) : fond immersif, UI en overlay semi-transparent ou en carte blanche latérale.
- **Layout deux colonnes** (settings) : sidebar de catégories à gauche (~250px), grille de contenu à droite (2 colonnes de tuiles).
- **Layout grille responsive** (library, home) : rangée(s) de cartes de largeur fixe, défilement horizontal implicite (la dernière carte est coupée dans les mockups).
- **Layout liste verticale pleine largeur** (notifications, messages, menu rapide sidebar) : lignes empilées bordées, largeur contrainte à gauche de l'écran.
- **Layout overlay centré** (clavier virtuel, capture) : zone de contenu en haut, contrôle (clavier, choix capture) ancré en bas de l'écran.

## 4. Overlays

- **Quick Menu** (`menu (rapide)/`) : sidebar + onglets superposés à l'écran courant, cohérent avec CLAUDE.md section 27 (overlay qui ne doit pas reconstruire la page derrière).
- **Overlay de capture** (`overlay/`) : boîte de dialogue modale centrée avec choix (screenshot/vidéo) puis confirmation.
- **Clavier virtuel** : overlay bas d'écran au-dessus d'un champ de texte actif (messages, recherche amis).
- **Toasts de notification** (home-notifications-*) : overlay transitoire coin d'écran, distinct du centre de notifications persistant.

## 5. Navigation

Voir docs/ui-navigation.md pour le graphe complet. Résumé : Boot → Login/Sélection
de profil → Home → {Library, Quick Menu, Settings, Profile, Notifications,
Messages, Album} avec retour systématique vers Home ou la page précédente.
Aucun écran « Game Detail » dédié n'apparaît dans les maquettes fournies : la
sélection d'une jaquette dans Library ou Home semble mener directement au
lancement ou à un menu contextuel (`library 1-5 menu.png`). **Ambiguïté à
lever avec l'utilisateur** avant d'implémenter Game Detail (section 26 du
prompt maître place pourtant Game Detail entre Library et Hello Console).

## 6. Modèles de données sous-jacents

Déduits des écrans, à confirmer avant modélisation formelle :

- **Utilisateur/Profil** : id, pseudo, avatar, statut de présence, liste d'amis, achievements, activité récente, stats par jeu, abonnements.
- **Jeu (catalogue)** : id, titre, jaquette, achievements (progression x/N), état favori — correspond au manifest `game.json` déjà implémenté côté Game Manager pour les champs id/nom/exécutable, à étendre pour jaquette/achievements en phase ultérieure.
- **Notification** : type (ami connecté, message, invitation, demande d'ami, achievement, périphérique), émetteur, horodatage, action associée.
- **Message/Conversation** : liste de messages horodatés entre deux utilisateurs.
- **Média (album)** : type (screenshot/vidéo), jeu source, date.
- **Paramètre système** : catégorie (General/Account/System/Devices/Preferences) → sous-catégorie → clé/valeur (affichage, thème, contrôle parental, langue, date/heure, réseau, manette/mapping, souris, clavier, notifications, capture).

## 7. Risques de propriété intellectuelle (CLAUDE.md section 6)

Deux écrans haute fidélité intègrent une identité visuelle tierce directement
reconnaissable et **ne doivent jamais être copiés dans le produit** :

1. **`login/login.png`** : reprend intégralement le branding Valorant (Riot Games) — illustration de personnage, logo, palette rouge/marine.
2. **`home/home 1.jpg`** : reprend la disposition du dashboard Xbox (rangée de jaquettes, horloge, icône manette, libellé explicite « XBOX CONTROLLER », boutons « A Start »/« + Options ») et utilise de vraies jaquettes de jeux commerciaux (Ghost of Tsushima, The Last of Us Part II, God of War...).

Ces deux écrans doivent être traités comme des **références fonctionnelles
uniquement** (structure de layout, hiérarchie de l'information). Voir ADR-004
dans `.ai/DECISIONS.md`. Le développement doit utiliser des placeholders
(« Hello Console », illustrations libres) conformément à la section 6 du
prompt maître.

## 8. Ce que ce document ne couvre pas encore

- Extraction précise des valeurs de couleur/typographie/spacing pixel par
  pixel (fait dans docs/design-system.md à partir des écrans les plus
  représentatifs, pas des 160 fichiers un par un — voir limite de section 9).
- Spécification exhaustive écran par écran (hors périmètre du MVP, section 26
  du prompt maître : ne pas implémenter toutes les maquettes immédiatement).

## 9. Méthode et limite assumée

Compte tenu du volume (160 fichiers), l'analyse a porté sur un échantillon
représentatif de chaque famille d'écran (boot, login, home, library, settings
General, menu rapide, clavier virtuel, notifications) plutôt que sur une
inspection exhaustive pixel par pixel de chaque fichier. Les familles à forte
volumétrie mais forte répétition structurelle (settings : 61 fichiers,
profile : 41 fichiers) partagent un même patron de layout deux-colonnes/liste
déjà décrit en section 3 — une inspection complète n'aurait pas changé les
composants du design system. Si un écran précis doit être implémenté et que
son détail n'est pas couvert ici, le rouvrir individuellement au moment de
l'implémenter (protocole incrémental, CLAUDE.md section 46).
