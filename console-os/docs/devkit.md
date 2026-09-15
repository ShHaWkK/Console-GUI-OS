# Contrat DevKit proposé (TODO, non implémenté)

Le SDK tourne sur le PC développeur. La console n'embarque pas de compilateur
dans l'image Retail. Le Developer System est une distribution d'outils et un
profil de console compatible avec le même runtime, pas un fork de la plateforme.

| Commande future | Fonction |
|---|---|
| consolectl build | Compiler avec sysroot et version SDK déclarés |
| consolectl package | Valider manifest, inventorier, signer le build |
| consolectl devices / connect | Découverte opt-in et appairage avec empreinte |
| consolectl install / uninstall | Transaction de package autorisée |
| consolectl launch / stop / info | Appels du Game Manager par ID |
| consolectl logs | Flux borné, reprise et filtres |
| consolectl screenshot | Capture autorisée du compositor |
| consolectl system-info | Informations expurgées de secrets |

Protocole distant versionné, erreurs stables, TLS mutuel, rotation et révocation
des certificats. L'agent exige Developer Mode actif pour chaque commande, pas
seulement à la connexion. Debug attach seulement aux jeux de développement.

Activation locale : authentification de l'administrateur → consentement visible
→ code d'appairage éphémère → certificat du poste reconnu. Retour Retail : couper
les connexions, arrêter les jeux dev, interdire leurs builds et désactiver l'agent.

Arborescence SDK cible : bin/, include/, lib/, sysroots/, templates/, tools/, docs/.
MVP actuel : le build CMake de Hello Console et le catalogue local démontrent
compilation/lecture/lancement ; packaging, transfert et CLI ne sont pas simulés.
