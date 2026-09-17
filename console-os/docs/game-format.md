# Format de jeu : manifest et package

Statut : le manifest est **implémenté et testé** ; le format de package
`.gamepkg` est une **proposition non implémentée** (TODO phase 3). Répond à
CLAUDE.md sections 20 et 21. Complète `packaging/README.md` et
`packaging/game.schema.json` déjà présents dans le dépôt.

## 1. Manifest `game.json` — IMPLEMENTED

Implémenté dans `core/manifest.cpp` / `core/manifest.h`, testé par 20 cas
dans `tests/test_manifest.cpp` (voir docs/validation.md).

Champs actuellement acceptés (liste fermée — tout champ inconnu est rejeté) :

```json
{
  "schema_version": 1,
  "id": "com.console.hello",
  "name": "Hello Console",
  "version": "0.1.0",
  "developer": "Console SDK",
  "executable": "bin/hello-console",
  "runtime": "native",
  "permissions": [],
  "controller_support": true
}
```

Différences avec la proposition initiale de CLAUDE.md section 20 : le champ
`architecture` (liste x86_64/aarch64) et le sous-objet `assets` (icon/cover)
**ne sont pas encore implémentés** dans `core/manifest.cpp` — le code actuel
attend exactement l'ensemble de champs ci-dessus, ni plus ni moins
(`missing_field`/`unknown_field` si écart). Ajouter `architecture` et
`assets` est une évolution de schéma à faire consciemment (bump de
`schema_version` ou champs optionnels rétrocompatibles), pas une extension
silencieuse.

Validations réellement appliquées (vérifiées par les tests, pas supposées) :

- JSON strictement valide, objet racine, taille ≤ 65536 octets
- Ensemble de champs fermé (`unknown_field` / `missing_field`)
- `schema_version` doit valoir exactement `1`
- Chaînes non vides, ≤ 256 caractères, sans caractères de contrôle
- `id` : regex `^[a-z][a-z0-9]*(?:\.[a-z][a-z0-9_-]*)+$`, et doit être
  identique au nom du dossier contenant le manifest (anti-usurpation de
  catalogue)
- `version` : semver strict `MAJOR.MINOR.PATCH` sans zéro non significatif
- `runtime` doit valoir `"native"` (seule valeur supportée actuellement —
  pas de runtime alternatif implémenté)
- `permissions` doit être un tableau **vide** (aucune permission n'est encore
  supportée — tout tableau non vide est rejeté explicitement, pas ignoré)
- `controller_support` booléen strict
- `executable` : chemin relatif, sans `\`, sans composant `.`/`..`, aucun
  composant intermédiaire symlink, résolu et vérifié comme fichier
  exécutable réel contenu **sous** le dossier du jeu (canonicalisation +
  vérification d'inclusion, protège contre le path traversal)
- Le dossier du jeu lui-même doit être un sous-dossier direct, non-symlink,
  du catalogue racine

Chemins absolus et `../` sont donc déjà refusés dans le code, pas seulement
documentés comme intention.

## 2. Format de package `.gamepkg` — TODO (phase 3, non implémenté)

Aucun code de packaging n'existe. Proposition reprise telle quelle de
CLAUDE.md section 21, à affiner au moment de l'implémentation :

```text
manifest
executables
assets
resources
authorized dependencies
developer information
hashes
signature
```

Objectifs (non implémentés) : reproductibilité, versioning, signature
cryptographique, intégrité, installation, update, rollback. Conformément à
CLAUDE.md section 21, **ne pas développer d'infrastructure cryptographique
improvisée** — utiliser des primitives standards (à choisir en Rust au
moment de la phase 3 : `ring`/`rustls`-ecosystem ou équivalent maintenu,
décision à documenter dans un ADR dédié le moment venu, pas ici par
anticipation).

`packaging/README.md` documente déjà explicitement ce TODO et précise que
les fichiers du catalogue local actuel sont des builds de confiance, pas des
packages Retail signés — cohérent avec ce document, aucune contradiction à
corriger.

## 3. JSON Schema

`packaging/game.schema.json` existe déjà dans le dépôt. Vérifier au moment de
la prochaine évolution de `core/manifest.cpp` que le schéma JSON et la
validation C++ restent synchronisés (actuellement deux sources de vérité
distinctes — un test de cohérence schéma/code serait une amélioration utile,
ajoutée à `.ai/NEXT.md` si elle n'y est pas déjà).
