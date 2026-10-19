# Programme de la prochaine mise à jour (3.3.0) et notes de reprise

Dernière version publiée : **3.2.0** (`main` = tag `v3.2.0`). Ce fichier sert de point de reprise : il résume l'état du projet,
ce qui reste à valider, et propose le contenu de la 3.3.0 par ordre de priorité.

---

## 1. État du projet (à retenir)

**Le jeu** : platformeur 3D low-poly, Godot 4.3, tout est généré par code (aucun asset externe). Lumi (robot) traverse 12 mondes
+ 3 secrets, parcours générés par seed, 18 types de dalles, 5 boss, modes Aventure / Éclair / Infini / Monde libre / Défis,
fantôme, étoiles, cosmétiques, 16 modificateurs, 29 succès, 6 langues, clavier / manette / tactile, Windows / Linux / macOS / Web / Android.

**Fichiers clés** : `scripts/global.gd` (autoload : run, modes, défis, codes, options, audio, sauvegarde), `generator.gd` (parcours),
`level_data.gd` (mondes), `level.gd` (étape), `player.gd`, `platform.gd` (18 types), `boss.gd`, `decor.gd`, `translations.gd`
(généré), `tests/smoke.gd` (230 vérifications), `tests/bot.gd` (robot joueur), `tools/` (build, audio, captures), `docs/`.

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
- Les `git push` demandent l'accord explicite du propriétaire ; les tags suivent `vX.Y.Z` ; le CI GitHub (`.github/workflows/build.yml`) n'a jamais été vérifié sur GitHub.
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

## 3. Contenu proposé pour la 3.3.0

Objectif : **« Sensation de jeu et finition »** — consolider ce qui existe avant d'ajouter encore du contenu. Les blocs sont
indépendants ; l'ordre ci-dessous est l'ordre conseillé.

### Bloc A — Finition et équilibrage (à faire en premier, dépend de V1 à V3)

- Corriger tout ce qui ressort de la session de jeu (V1) : réglages de caméra par défaut, vitesse, double saut, lisibilité.
- Régler bumpers / glace / canons (V2) ; enseigner le robot de test à les contourner, pour retrouver un indicateur fiable (> 95 %).
- Rééquilibrer les 5 boss (V3) et ajouter un **indicateur de danger** (flèche hors écran vers le prochain tir ou rayon).
- Réglages de difficulté fins : le niveau « Détendu » doit permettre à un débutant de finir les 12 mondes.
- Revue de performances (Android, Web) : profil des 3 pires mondes, limite de particules et de décors par appareil.

### Bloc B — Confort et accessibilité

- **Navigation manette dans les menus** (focus, A / B), et remappage des boutons de la manette.
- **Mode une main / disposition tactile gauchers** (inverser joystick et bouton de saut) et taille / position des boutons réglables.
- Option **réduire les secousses et flashs** (particules, clignotement des dalles), contraste élevé pour le HUD.
- **Sous-titres sonores** optionnels (« tir de canon à droite ») pour les joueurs sourds ou malentendants.
- Sauvegarde : **export / import** du fichier de progression (copie manuelle) et sauvegarde de secours automatique.

### Bloc C — Nouveau contenu (si V1 à V3 sont réglés)

- **Mode « Contre-la-montre pur »** : une étape, un classement des meilleurs temps par seed, fantôme du record du jour.
- **Défi de boss** : mode qui enchaîne les 5 boss avec une barre de vie persistante.
- **Mode photo** dans la pause (cacher le HUD, caméra libre, capture enregistrée dans le dossier utilisateur).
- **Nouveaux pièges** : plateforme qui rétrécit, aimant à pièces, zone de gravité inversée, tapis de vent.
- **Monde 16 « Atelier »** : un monde-bac à sable pour s'entraîner à chaque type de dalle, avec les astuces intégrées (tutoriel).
- **Saisonnier** : thèmes temporaires (couleurs / décors d'événement) sans changer le jeu.

### Bloc D — Audio (dépend des fichiers livrés)

Voir `audio/README.md` (noms, durées, ambiances). Reste à fournir :

- **Musiques (18)** : `menu`, `story`, `boss`, `world_01` … `world_15` (boucles sans coupure) ; jingles `win`, `run_complete` fournis, `lose` fourni (`loose`).
- **Effets (8 nouveaux)** : `bumper`, `star`, `boss_wake`, `boss_shot`, `boss_beam`, `equip`, `streak`, `tip` (remplacent la synthèse).
- Éventuellement : sons d'ambiance par monde (vent, océan, usine…) en boucle basse, `audio/ambience/` (à créer dans le code).

### Bloc E — Langues et audience

- Langues à ajouter selon la demande : **néerlandais, polonais, russe, turc** (alphabet latin ou cyrillique, police par défaut suffisante).
- **Japonais / chinois / coréen** : demandent une police bundlée (le jeu n'en embarque aucune) → ajouter une police sous licence libre pour que le Web et Android affichent les caractères.
- Détection de la langue du navigateur pour la version Web.

### Bloc F — Publication

- Captures d'écran et bande-annonce (`tools/screenshots.gd`, `docs/STORE_PAGE.md`) ; page itch.io ; fiche Google Play (AAB signé, `docs/ANDROID.md`).
- Signature et notarisation macOS (`docs/MACOS_SIGNING.md`) si compte Apple disponible.
- Classement en ligne : **nécessite un serveur** (non prévu) ; alternative sans serveur : classement partageable par code (un code qui contient score + seed à coller).

---

## 4. Critères d'acceptation de la 3.3.0

- `tests/smoke.gd` : « TOUT PASSE » ; robot de test ≥ 95 % de parcours réussis (hors modificateurs extrêmes).
- Une personne autre que le développeur finit l'Aventure en « Détendu » sans aide.
- APK testé sur au moins 2 téléphones (un bas de gamme) : 30 images par seconde en qualité Basse, commandes lisibles.
- Aucun texte tronqué dans les 6 langues (V7), toutes relues (V6).
- Version Web jouable dans Chrome et Firefox, audio compris.
- CHANGELOG, README et `docs/STORE_PAGE.md` à jour ; tag `v3.3.0` poussé et CI verte.

---

## 5. Questions à trancher avant de commencer

1. Priorité : **finition d'abord** (blocs A, B) ou **nouveau contenu** (bloc C) ? (recommandé : finition d'abord.)
2. Quelles langues supplémentaires (bloc E) ?
3. Une version payante / gratuite ? (influence la page de boutique et la politique de confidentialité).
4. Besoin d'un classement en ligne (serveur à prévoir) ou le classement local suffit-il ?
5. Musiques : combien seront livrées d'ici la sortie (le reste restera synthétisé) ?
