# Cloud Gaming — préparation d'architecture

Statut : proposition v0.1, 17 septembre 2026. Répond à CLAUDE.md section 32.
Ce document prépare l'évolution cloud sans prétendre livrer une plateforme
industrialisée maintenant (phase 8/9 de la roadmap, pas la tranche actuelle).

## 1. Pipeline vidéo cible

```text
Game
 ↓
Vulkan (via Console SDK)
 ↓
GPU (instance AWS ARM64/GPU)
 ↓
Hardware Encoder (NVENC ou encodeur équivalent selon l'instance)
 ↓
Streaming Transport (à choisir : WebRTC probable pour la latence)
 ↓
Internet
 ↓
Client (Linux/Windows/macOS)
 ↓
Hardware Decoder
 ↓
Display
```

## 2. Pipeline d'entrée cible

```text
Controller (client)
 ↓
Client
 ↓
Network
 ↓
Input Service (côté session cloud)
 ↓
Virtual Controller (uinput ou équivalent)
 ↓
Game
```

Le pipeline d'entrée doit réutiliser l'abstraction `NavigationAction` /
mapping manette déjà posée côté shell local (CLAUDE.md section 24), pas une
API distincte pour le cloud.

## 3. Points à étudier avant toute décision d'architecture figée

- **ARM64 sur AWS** : Graviton pour le calcul général ; à vérifier lesquelles
  des instances GPU actuelles (typiquement x86_64 aujourd'hui pour les
  familles G/P) offrent un chemin ARM64+GPU viable. NOT TESTED / non vérifié
  dans cette session — à consulter dans la documentation AWS à jour au
  moment de la décision (CLAUDE.md section 32 : ne jamais supposer que les
  offres AWS sont immuables).
- **Pilotes GPU** : disponibilité et support des pilotes propriétaires
  (NVIDIA) ou open (Mesa) sur les AMI ARM64 ciblées.
- **Vulkan** : version supportée par les pilotes de l'instance retenue.
- **Encodage matériel** : codec (H.264 baseline pour la compatibilité large,
  AV1/HEVC pour l'efficacité si le client le supporte), bitrate adaptatif.
- **Latence / perte de paquets** : le choix de transport (WebRTC vs solution
  propriétaire) doit être motivé par des mesures réelles, pas supposé.
- **Isolation de session** : chaque session cloud doit rester dans le même
  modèle de moindre privilège que la console locale (pas de root, pas de
  service exposé sans authentification) — cohérent avec docs/security.md.
- **Orchestration / autoscaling** : hors périmètre MVP (CLAUDE.md section 64
  liste explicitement l'autoscaling AWS comme « ne pas commencer encore »).
- **Coût par session / utilisateurs simultanés** : à chiffrer une fois un
  premier prototype technique validé, pas avant.

## 4. Ce qui existe déjà et qui prépare le cloud

- Le Game Manager sépare déjà lancement/arrêt/logs du rendu (D-Bus), ce qui
  est compatible avec un futur détachement entre session de rendu (côté GPU
  cloud) et contrôle (côté client). Aucune réécriture nécessaire pour cette
  tranche.
- Le modèle de sécurité (refus root, API par ID, pas de commande arbitraire)
  s'applique identiquement à une session cloud multi-locataire, où les
  enjeux d'isolation sont plus critiques qu'en local.

## 5. Explicitement hors périmètre actuel

Conformément à CLAUDE.md section 64 : pas d'implémentation AWS de
production, pas d'autoscaling, pas de client cloud gaming fonctionnel dans
cette tranche. Ce document est une préparation d'architecture, pas un plan
d'exécution daté.
