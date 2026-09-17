# Next Tasks

## Current

[ ] Évalué : extraction `MenuItem` entre onglets et catégories Settings jugée non rentable pour l'instant (styles visuels réellement différents, pas juste une duplication cosmétique) — voir docs/design-system.md section 4. Prochaine tâche réelle à choisir ci-dessous.

## Next

[ ] Écrire un backend manette physique (SDL3 ou évènements evdev) branché sur l'enum NavigationAction déjà présent côté shell, et sur l'action "menu" du Quick Menu (bouton Home manette). NOT TESTABLE avec un vrai périphérique dans cette session (WSL2 sans passthrough USB) — prévoir une validation sur machine Linux avec manette physique avant de considérer la tâche vérifiée.
[ ] Écran Game Detail minimal (voir docs/ui-navigation.md section 4 — traiter le menu contextuel Library comme version MVP, confirmer avec l'utilisateur si besoin)

## Later

[ ] Profils/Login/Boot screen réels (actuellement maquette uniquement, IP tierce à remplacer — voir docs/ui-analysis.md section risques)
[ ] Clavier virtuel QML (maquette/virtual keyboard/)
[ ] Gamescope réel en nested puis embedded sur matériel Arch (hors de portée de WSL, nécessite machine Linux avec GPU)
[ ] ARM64 : premier build croisé ou natif, même minimal, pour sortir du statut NOT TESTED
