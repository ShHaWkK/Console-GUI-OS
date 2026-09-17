# Known Issues

## ISSUE-001 — RÉSOLU 2026-09-17

Component:
Environnement de travail (cette session)

Problem:
La session tournait sur Windows 11 sans toolchain Linux/Qt6/CMake/g++/dbus installée. Impossible de rejouer réellement le build/tests.

Resolution:
L'utilisateur a installé `build-essential cmake qt6-base-dev qt6-declarative-dev libdbus-1-dev` dans WSL2 Ubuntu 24.04. Build et 3 suites CTest rejoués avec succès le 2026-09-17 (voir .ai/STATUS.md). Reste non couvert : rendu graphique réel (pas de serveur Wayland dans WSL) et boot Arch/Gamescope matériel — nécessitent toujours une machine Linux dédiée avec GPU.

Severity:
Résolu (High avant résolution)

## ISSUE-002 — RÉSOLU 2026-09-17

Component:
Recette D-Bus interprocessus (tests/integration.py)

Problem:
Cette suite n'avait jamais été exécutée avec succès dans un environnement de vérification connu : ignorée explicitement sous root, et les environnements testés jusque-là restreignaient les sockets Unix nécessaires à un vrai bus D-Bus de session.

Resolution:
Exécutée avec succès le 2026-09-17 dans WSL2 Ubuntu 24.04, utilisateur non-root (`shhawk`) : catalogue, lancement, concurrence, arrêt, échec exécutable et manifest hostile — PASS en 0.43s contre le vrai daemon `game-manager` compilé. Log complet dans `console-os/build-wsl/Testing/Temporary/LastTest.log` (build local non versionné, à rejouer si besoin de le revoir).

Severity:
Résolu (Medium avant résolution)

## ISSUE-004 — RÉSOLU 2026-09-17

Component:
Smoke test QML (tests/qml_smoke.py)

Problem:
Le script échouait de façon non déterministe (observé ~1 exécution sur 2, 6 exécutions consécutives testées pour confirmer) avec des `TypeError: Cannot read property 'message'/'games'/'gameRunning' of null` imprimées **après** son propre message PASS. Cause : à la fin normale du script, CPython libère les objets de module (`backend`, `engine`, `window`...) dans un ordre non garanti ; si le wrapper Python `backend` (exposé comme contexte QML) est libéré avant le moteur QML `engine`, des bindings QML encore vivants se ré-évaluent contre un contexte détruit.

Investigation :
Vérifié que le binaire réel (`shell/main.cpp`) n'est pas concerné : `Backend backend;` est déclaré avant `QQmlApplicationEngine engine;`, donc le C++ détruit toujours le moteur avant le backend (ordre inverse de construction) — la panne est spécifique au script de test Python, pas à la logique QML/C++ elle-même.

Resolution:
`tests/qml_smoke.py` détruit maintenant explicitement `engine`/`hello` avant `backend`, en fin de script, reproduisant l'ordre sûr du binaire réel. 6/6 exécutions propres après correction. Le test est aussi désormais enregistré dans CTest (`qml-smoke`, SKIP si PySide6 absent) pour que ce genre de régression soit détecté automatiquement au lieu de dépendre d'une exécution manuelle occasionnelle.

Severity:
Résolu (Medium avant résolution — un test flaky non détecté peut masquer une vraie régression future)

## ISSUE-005 — Non un problème, revue effectuée

Component:
Game Manager (services/game-manager/manager.cpp, main.cpp)

Problem:
Revue de robustesse demandée par l'utilisateur (« je veux que tout soit... robuste »).

Resolution:
Relecture complète : refus root (manager et shell), double-lancement bloqué explicitement, arrêt gracieux SIGTERM puis SIGKILL après 3s (`killTimer_`), environnement du processus enfant reconstruit avec allowlist stricte (pas d'héritage de LD_PRELOAD etc.), manifest revalidé juste avant le lancement (pas seulement au listing, protège contre un TOCTOU catalogue modifié entre-temps), logs de sortie du jeu limités en débit (16 Ko/s) pour éviter un déni de service par flood de stdout, échec d'enregistrement D-Bus (ex. instance déjà active) détecté et journalisé avec sortie propre plutôt qu'un crash. Aucun changement de code jugé nécessaire : le composant est déjà robuste pour son périmètre actuel. Limite connue et déjà documentée ailleurs (pas un bug) : le jeu partage l'UID de session, pas de sandbox — prévu en phase 6 (docs/security.md).

Severity:
N/A (revue, pas un défaut)

## ISSUE-006 — RÉSOLU 2026-09-17

Component:
Shell QML (shell/Main.qml), page Settings

Problem:
L'ajout de la rangée de catégories Settings (General/Account/System/Devices/Preferences) augmentait la hauteur de contenu au-dessus de la carte principale sans que la hauteur réservée à la carte (`Math.max(220, window.height - 455)`, une constante calibrée pour l'ancien layout) soit recalculée. Résultat visuel : le texte de statut et le bandeau d'aide en bas d'écran se chevauchaient sur la page Settings uniquement.

Investigation :
Trouvé par vérification visuelle réelle (capture d'écran hors-écran via PySide6/QQuickWindow.grabWindow, pas une supposition) — les 4 suites CTest ne pouvaient pas détecter ce problème car elles ne comparent pas le rendu pixel par pixel.

Resolution:
Hauteur de la carte réduite de 64px (hauteur de la rangée + spacing) spécifiquement sur la page Settings (`shell/Main.qml`). Reconfirmé par une nouvelle capture d'écran après correction : plus de chevauchement.

Severity:
Résolu (Low — cosmétique, mais démontre l'intérêt de vérifier visuellement plutôt que de supposer qu'un changement de layout QML n'a pas d'effet de bord)

## ISSUE-003

Component:
Maquettes UI (maquette/)

Problem:
Plusieurs écrans haute fidélité des maquettes réutilisent une identité visuelle tierce clairement identifiable : le login reprend le branding Valorant (Riot Games) tel quel, et le Home reprend la disposition du dashboard Xbox avec le libellé explicite « Xbox Controller » et de vraies jaquettes de jeux commerciaux (Halo, Gears of War, Overwatch, The Last of Us, God of War...).

Severity:
Medium (risque de propriété intellectuelle si intégré tel quel — voir CLAUDE.md section 6 et section « Interdictions »)

Temporary workaround:
Aucun code n'a été écrit à partir de ces écrans. Voir ADR-004 dans .ai/DECISIONS.md et docs/ui-analysis.md.

Future fix:
Concevoir les écrans Home/Login finaux avec des assets placeholder internes (« Hello Console », illustrations libres), en conservant seulement l'intention UX (carrousel de jeux, sélection de profil).
