# Programme de la prochaine mise à jour (3.6.0) et notes de reprise

Dernière version publiée : **3.5.0** (`main` = tag `v3.5.0`). Historique récent : 3.3.0 flèches de danger, mode gaucher, effets réduits, sauvegarde (code + copie de secours) ; 3.4.0 mode photo, sous-titres sonores, contraste, navigation manette ; 3.5.0 Contre-la-montre du jour, Défi des 5 boss, 3 nouvelles dalles (rétrécit, vent, aimant), monde 16 « Atelier », 4 langues (nl, pl, tr, ru). Ce fichier sert de point de reprise : il résume l'état du projet,
ce qui reste à valider, et propose le contenu de la 3.6.0 par ordre de priorité.

---

## 1. État du projet (à retenir)

**Le jeu** : platformeur 3D low-poly, Godot 4.3, tout est généré par code (aucun asset externe). Lumi (robot) traverse 12 mondes
+ 4 secrets, parcours générés par seed, 21 types de dalles, 5 boss, modes Aventure / Éclair / Infini / Monde libre / Contre-la-montre / Défi des boss / Défis,
fantôme, étoiles, cosmétiques, 16 modificateurs, 31 succès, 10 langues, clavier / manette / tactile, Windows / Linux / macOS / Web / Android.

**Fichiers clés** : `scripts/global.gd` (autoload : run, modes, défis, codes, options, audio, sauvegarde), `generator.gd` (parcours),
`level_data.gd` (mondes), `level.gd` (étape), `player.gd`, `platform.gd` (18 types), `boss.gd`, `decor.gd`, `translations.gd`
(généré), `tests/smoke.gd` (~290 vérifications), `tests/bot.gd` (robot joueur), `tools/` (build, audio, captures), `docs/`.

**Commandes utiles** (toujours en `--headless`, aucune fenêtre) :

```bash
godot --headless --path . --script tests/smoke.gd            # doit afficher « TOUT PASSE »
godot --headless --path . --script tests/bot.gd -- 0 3       # robot joueur (seeds 0 à 2, 15 mondes)
godot --headless --path . --script tools/check_audio.gd      # audio fourni / manquant
tools/build_all.sh windows linux web macos android           # exports (ou tools/build_all.ps1 sous Windows)
```

**Environnement de travail (poste de développement)** :

- Godot 4.3 utilisé pour les tests : `C:\gdt\Godot_v4.3-stable_win64_console.exe` (copie autonome, « Safe Save » désactivé car l'antivirus bloque les fichiers temporaires). Modèles d'export 4.3 installés ; Android : JDK de Android Studio + SDK + keystore debug.
- Lancer Godot **sans** `--headless` ouvre une fenêtre : à éviter (sauf `tools/screenshots.gd`, volontairement visuel).
- Les tests modifient la sauvegarde : supprimer `save.cfg` et `ghosts.dat` du dossier `%APPDATA%\Godot\app_userdata\Diamant Rush 3D\` après.
- Les `git push` se font à la demande du propriétaire (il a demandé « fais la mise à jour et push » pour 3.3.0 et 3.4.0) ; les tags suivent `vX.Y.Z` ; le CI GitHub (`.github/workflows/build.yml`) n'a jamais été vérifié sur GitHub.
- Les traductions se régénèrent depuis un index numéroté (français → langues) : ajouter une chaîne = l'ajouter dans les 5 dictionnaires de `translations.gd`.

---

## 2. Dette connue et validations à faire (priorité absolue)

Rien de ce qui suit n'a été vérifié par un humain : le jeu n'a été testé qu'en simulation headless.

| # | Sujet | Détail | Action |
|---|---|---|---|
| V1 | **Jouer au jeu** | Aucun test visuel / de sensation : caméra, vitesse, saut, lisibilité des pièges, performances | Session de jeu complète sur PC, noter tout ce qui gêne |
| V2 | **Bumpers, plaques de glace, canons** | Le robot de test les gère mal (~83 % de réussite globale) : il faut juger à la main s'ils sont justes | Jouer les mondes 7, 10, 11, 13, 14 ; ajuster `scripts/platform.gd` (zone et poussée du bumper) et les poids de `level_data.gd` |
| V3 | **Équilibre des boss** | 5 boss jamais combattus par un humain (durée, vitesse, rayon rotatif) | Combattre les 5, ajuster `boss.gd` (`duration`, cadence, vitesse du rayon) |
| V4 | **Mobile réel** | Commandes tactiles, qualité basse, encoche, bouton retour : jamais testés sur un téléphone | Installer l'APK, noter les problèmes |
| V5 | **CI GitHub** | Workflow jamais exécuté ; étape Android non testée | Lancer « Build » depuis l'onglet Actions, corriger |
| V6 | **Traductions** | ES / DE / IT / PT rédigées par IA | Relecture par des locuteurs natifs |
| V7 | **Textes qui débordent** | Les langues plus longues (DE, PT) peuvent dépasser les boutons | Parcourir les 11 pages de menu dans chaque langue à l'écran |
| V8 | **Web** | Export construit mais jamais lancé dans un navigateur (audio, tactile, mémoire) | Servir `build/web` et tester sur PC et mobile |

---

## 3. Contenu proposé pour la 3.6.0

**Rien de ce qui a été ajouté en 3.3 → 3.5 n'a été essayé à la main** (flèches de danger, mode photo, nouvelles dalles, nouveaux modes,
traductions). La 3.6.0 doit donc d'abord être une version de finition.

### Bloc A — Finition (priorité absolue, dépend de V1 à V3)

- Session de jeu complète : caméra, vitesse, saut, lisibilité ; équilibrage des bumpers / glace / canons, des **3 nouvelles dalles** (rétrécit : vitesse et taille minimale ; vent : force 4,5 ; aimant : durée et rayon) et des 5 boss.
- Enseigner au robot de test à contourner les pièges (et aux nouvelles dalles) pour retrouver un indicateur fiable (> 95 %).
- Vérifier le **Défi des 5 boss** (parcours courts assez courts ? 3 vies suffisent-elles ?) et le **Contre-la-montre** (choix du monde du jour).
- Revue de performances (Android, Web) ; vérifier les flèches de danger et la capture réelle du mode photo (hors headless).
- Relecture native des 9 traductions IA ; textes qui débordent (V7), en particulier DE, PT, RU, PL, TR.

### Bloc B — Confort restant

- Remappage des boutons de la manette ; taille / position réglables des boutons tactiles.
- Sliders des options entièrement utilisables à la manette ; sous-titres directionnels (« à gauche »), plus de sons couverts.

### Bloc C — Contenu non commencé

- **Gravité inversée** (zone ou dalle) : demande de revoir le sol / les collisions du joueur.
- **Saisonnier** : thèmes temporaires (couleurs / décors d'événement).
- Classement du Contre-la-montre partageable par code (pas de serveur), mode photo sur mobile.
- Nouveaux boss ou mondes, selon les retours des joueurs.

### Bloc D — Audio (dépend des fichiers livrés)

Voir `audio/README.md`. À fournir : 19 musiques (`menu`, `story`, `boss`, `world_01` … `world_16`) et 8 effets (`bumper`, `star`,
`boss_wake`, `boss_shot`, `boss_beam`, `equip`, `streak`, `tip`) ; ambiances par monde en option. Idées d'effets propres aux nouvelles dalles
(rétrécissement, souffle de vent, aimant) : aujourd'hui elles réutilisent `crumble` et `checkpoint`.

### Bloc E — Langues et audience

- Japonais / chinois / coréen : embarquer une police sous licence libre (le jeu n'en embarque aucune). Détection de la langue du navigateur pour le Web.

### Bloc F — Publication

- Captures et bande-annonce, page itch.io, fiche Google Play (AAB signé), notarisation macOS, première exécution du CI GitHub.

---

## 4. Critères d'acceptation de la 3.6.0

- `tests/smoke.gd` : « TOUT PASSE » ; robot de test ≥ 95 % de parcours réussis (hors modificateurs extrêmes).
- Une personne autre que le développeur finit l'Aventure en « Détendu » sans aide.
- APK testé sur au moins 2 téléphones (un bas de gamme) : 30 images par seconde en qualité Basse, commandes lisibles.
- Aucun texte tronqué dans les 10 langues (V7), toutes relues (V6).
- Version Web jouable dans Chrome et Firefox, audio compris.
- CHANGELOG, README et `docs/STORE_PAGE.md` à jour ; tag `v3.6.0` poussé et CI verte.

---

## 5. Questions à trancher avant de commencer

1. Priorité : **finition d'abord** (blocs A, B) ou **nouveau contenu** (bloc C) ? (recommandé : finition d'abord.)
2. Quelles langues supplémentaires (bloc E) ?
3. Une version payante / gratuite ? (influence la page de boutique et la politique de confidentialité).
4. Besoin d'un classement en ligne (serveur à prévoir) ou le classement local suffit-il ?
5. Musiques : combien seront livrées d'ici la sortie (le reste restera synthétisé) ?
