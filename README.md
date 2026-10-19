# Diamant Rush 3D

Platformeur 3D low-poly réalisé avec **Godot 4.3**. Tu incarnes **Lumi**, un petit robot gardien de phare, et tu traverses les douze mondes d'un royaume flottant pour retrouver les éclats du Grand Diamant.

Tout est généré par code : **aucun asset externe** (modèles, textures, sons, musiques, particules). Tu peux déposer tes propres musiques et sons dans `audio/` (voir [audio/README.md](audio/README.md)).

- Version : **3.1.0** (voir [CHANGELOG.md](CHANGELOG.md))
- Plateformes : Windows, Linux, macOS, Web, **Android** (et iOS avec un Mac)
- Contrôles : clavier / souris, manette, écran tactile
- Langues : **français et anglais**
- Licence : MIT ([LICENSE](LICENSE))

---

## Sommaire

1. [Installation et lancement](#installation-et-lancement)
2. [Modes de jeu](#modes-de-jeu)
3. [Les 12 mondes et leurs boss](#les-12-mondes-et-leurs-boss)
4. [Commandes](#commandes)
5. [Plateformes et bonus](#plateformes-et-bonus)
6. [Modificateurs](#modificateurs)
7. [Score, succès, apparences, fantôme](#score-succès-apparences-fantôme)
8. [Défis et codes de partage](#défis-et-codes-de-partage)
9. [Options et accessibilité](#options-et-accessibilité)
10. [Génération procédurale et seeds](#génération-procédurale-et-seeds)
11. [Mobile](#mobile)
12. [Audio](#audio)
13. [Sauvegarde et vie privée](#sauvegarde-et-vie-privée)
14. [Structure du projet](#structure-du-projet)
15. [Tests](#tests)
16. [Construire les versions (exe, apk, web…)](#construire-les-versions-exe-apk-web)
17. [Problèmes fréquents](#problèmes-fréquents)

---

## Installation et lancement

### Depuis les sources

1. Installe **Godot 4.3 ou plus récent** (version standard, pas .NET) : <https://godotengine.org/download>.
2. Ouvre Godot, clique sur **Importer** et choisis `project.godot`.
3. Lance avec **F5**.

Rendu : *Forward+* sur ordinateur (Vulkan), *Compatibilité* (OpenGL) sur mobile et navigateur, configuré automatiquement.

### Depuis une version construite

Voir [Construire les versions](#construire-les-versions-exe-apk-web). Les archives (`windows`, `linux`, `macos`, `web`, `android`) sont aussi produites par la CI GitHub à chaque tag `vX.Y.Z`.

---

## Modes de jeu

| Mode | Contenu |
|---|---|
| **Aventure** | Les 12 mondes dans l'ordre, de plus en plus difficiles, avec toute l'histoire et 4 boss. |
| **Run éclair** | 5 mondes tirés selon la seed (un par palier de difficulté). |
| **Mode infini** | Étapes courtes qui s'enchaînent sans fin, de plus en plus dures, **3 vies** (une vie gagnée toutes les 3 étapes). Classement local. |
| **Monde libre** | Un seul monde au choix pour s'entraîner. |
| **Défis** | Défi du jour et défi de la semaine : seed et modificateurs imposés, objectif à atteindre pour gagner des pièces. |

Chaque étape : tombe dans le vide et tu réapparais au dernier **checkpoint** ; ramasse les pièces ; touche le **diamant**. Une run se termine à la fin du dernier monde, ou plus tôt en Hardcore / Contre-la-montre. Un **fantôme** de ton meilleur passage peut t'accompagner quand tu rejoues une même étape (même seed).

---

## Les 12 mondes et leurs boss

Chaque monde a ses couleurs, sa musique, ses décors, ses particules et sa **difficulté propre**.

| # | Monde | Difficulté | Particularité |
|---|---|---|---|
| 1 | Prairies Suspendues | [#....] | Tranquille : plateformes simples, premiers lanceurs |
| 2 | Forêt des Murmures | [#....] | Dalles clignotantes, ascenseurs, interrupteurs |
| 3 | Dunes d'Ambre | [##...] | Dalles friables, tapis roulants. **Boss** |
| 4 | Récif Céleste | [##...] | Plateformes orbitales, portails |
| 5 | Toundra de Givre | [##...] | **Sol glissant** en permanence, canons |
| 6 | Grotte des Cristaux | [###..] | Tourniquets, portails. **Boss** |
| 7 | Usine d'Engrenages | [###..] | Tapis roulants, ascenseurs, canons |
| 8 | Ruines Dorées | [###..] | Dalles qui s'effondrent, interrupteurs. **Boss** |
| 9 | Marais Spectral | [####.] | **Vent** permanent, portails |
| 10 | Volcan Endormi | [####.] | Tout en même temps |
| 11 | Cité Néon | [#####] | Rapide, dense en pièges |
| 12 | Ciel Infini | [#####] | Petites dalles, tous les pièges. **Boss** |

**Boss de fin des mondes 3, 6, 9 et 12 : l'Ombre.** Le diamant n'apparaît qu'après avoir survécu à ses attaques dans l'arène : balayages de boules à sauter, météores signalés par un cercle rouge, tirs ciblés. Tu as **3 vies** ; à zéro, tu repars du checkpoint et le combat recommence. Plus le monde est difficile, plus le combat est long et rapide.

---

## Commandes

| Action | Clavier / souris | Manette | Mobile |
|---|---|---|---|
| Bouger | `W A S D` / `Z Q S D` / flèches | Stick gauche | Joystick à gauche |
| Sauter / double saut | `Espace` | `A` | Bouton **SAUT** |
| Caméra | Souris | Stick droit | Glisser à droite |
| Pause | `Échap` ou `P` | `Start` | Bouton pause, bouton « retour » Android |
| Recommencer l'étape | `R` | `Y` | via le menu pause |

Les touches clavier sont reconnues par position physique : WASD fonctionne pareil en QWERTY et en AZERTY, et elles sont **réassignables** (Options → Accessibilité et touches). Relâcher le saut plus tôt donne un saut plus court. Un disque d'ombre sous Lumi montre où il va atterrir, et la caméra ne traverse pas les dalles.

---

## Plateformes et bonus

16 types de dalles. Le menu **Commandes** du jeu les rappelle ; l'option *Symboles sur les dalles* ajoute un petit repère sur chacune.

| Aspect | Type | Comportement |
|---|---|---|
| Couleur du monde | Normale | Solide |
| Bleu clair → vert | Checkpoint | Devient ton point de réapparition |
| Bleu vif | Mobile | Va et vient latéralement |
| Orange | Friable | Tremble puis tombe, réapparaît plus tard |
| Rose lumineux | Trampoline | Te propulse en hauteur |
| Violet | Clignotante | Disparaît périodiquement (elle clignote vite juste avant) |
| Gris à chevrons jaunes | Tapis roulant | Te pousse dans une direction |
| Turquoise | Orbitale | Tourne en cercle |
| Jaune | Ascenseur | Monte et descend |
| Chevrons jaune vif | **Lanceur** | Te propulse vers l'avant, au-dessus d'un grand vide |
| Dalle rouge avec un canon | **Canon** | Tire des boules latérales (le canon rougeoie avant de tirer) : saute ou passe entre deux tirs. Un tir te repousse. |
| Gris avec un bouton rouge | **Interrupteur** | Marche dessus : le **pont** transparent de la dalle suivante devient solide 8 secondes |
| Cyan transparent | **Pont** | Solide seulement quand l'interrupteur est actif |
| Anneau violet | **Portail** | Entre dans l'anneau : tu ressors sur la dalle suivante, de l'autre côté d'un très grand vide |
| Barre rouge | Tourniquet | Barre tournante à sauter |

Bonus flottants au-dessus de certains vides : **flèche orange** (vitesse +40 % pendant 6 s) et **ailes** (un saut supplémentaire pendant 12 s). Les **pièces dorées** augmentent le score et débloquent des apparences.

---

## Modificateurs

Réglables dans **Modificateurs** (menu principal ou nouvelle run). Ils se cumulent et multiplient le score.

| Modificateur | Effet | Multiplicateur |
|---|---|---|
| **Longueur** | Niveaux 1,5x / 2x / 3x plus longs (Longue, Très longue, Marathon) | x1.15 / x1.3 / x1.6 |
| **Difficulté** | Détendu (moins de pièges, plus de checkpoints) / Normal / Expert | x0.8 / x1 / x1.3 |
| Gravité lunaire / lourde | Sauts longs et flottants / chute rapide (même hauteur de saut) | x0.8 / x1.4 |
| Vitesse x1.5 | Tout va plus vite | x1.25 |
| Contre-la-montre | Temps limité par étape | x1.2 |
| Hardcore | Une chute = fin de la run | x1.8 |
| Sans double saut | Un seul saut | x1.5 |
| Niveaux en miroir | Parcours inversé | x1.1 |
| Sol glissant | Glace partout | x1.2 |
| Vent changeant | Direction et force variables | x1.2 |
| Dalles friables | Toutes les dalles normales s'effondrent | x1.4 |
| Lave qui monte | Une lave monte, il faut avancer | x1.5 |
| Brouillard épais | Visibilité réduite | x1.15 |
| Commandes inversées | Directions inversées | x1.3 |

Un bouton **Aléatoire** tire des modificateurs au hasard. Certaines combinaisons extrêmes sont volontairement très difficiles.

---

## Score, succès, apparences, fantôme

Score d'une étape :

```
(1000 + 150 × pièces + 10 × secondes de marge sur le temps de référence [+ 100 × numéro d'étape en mode infini]) × multiplicateur
```

Fin d'Aventure / Run éclair : **bonus de 1000 × multiplicateur**.

- **Classement local** : top 10 général et top 10 du mode infini (écran *Succès et statistiques*). Les records par mode sont aussi sauvegardés.
- **20 succès** : sans chute, toutes les pièces, marathon, Hardcore, run du jour, les 12 mondes, boss, mode infini, défi réussi, fantôme battu… Une annonce apparaît en jeu et à la fin de l'étape.
- **8 apparences de Lumi** (écran *Apparences*), débloquées avec le total de pièces : Orange, Bleu, Vert, Rose, Violet, Or, Ombre, Arc-en-ciel.
- **Statistiques** : temps de jeu, étapes et runs terminées, pièces, sauts, chutes, mondes terminés, boss vaincus, meilleure série infinie.
- **Fantôme** : ton meilleur passage d'une étape (même seed, même monde, même longueur, même difficulté, même miroir) est rejoué en transparence. L'option se coupe dans Options ; les 60 derniers fantômes sont conservés.

---

## Défis et codes de partage

### Défis du jour et de la semaine

Même défi pour tout le monde (calculé à partir de la date) : une Run éclair avec une **seed et des modificateurs imposés** et un **objectif** (au plus N chutes, au moins N pièces, ou en moins de X minutes). Réussir donne des pièces : **30** pour le défi du jour, **100** pour celui de la semaine (la semaine est en difficulté Expert avec 3 modificateurs).

### Codes de partage

Dans *Nouvelle run*, **Copier mon code** copie un code court qui contient le mode, la seed et tous les modificateurs, par exemple :

```
DR1-Q-482913-210-1A3
```

Un ami le colle dans *Utiliser* pour jouer exactement la même run, avec les mêmes réglages. Format : `DR1-<mode>-<seed>-<gravité><longueur><difficulté>-<modificateurs en hexadécimal>` (`A` Aventure, `Q` Éclair, `E` Infini, `F<n>` Monde libre n° n).

---

## Options et accessibilité

| Option | Rôle |
|---|---|
| Volumes (général, musique, effets) | 0 à 100 % |
| Sensibilité caméra, FOV, axe vertical inversé | Caméra |
| **Langue** | Automatique, Français, English |
| **Qualité** | Basse / Moyenne / Élevée (anticrénelage, ombres, lueur, nombre de décors et de particules). Basse par défaut sur mobile. |
| Ombres, plein écran | Ordinateur |
| Commandes tactiles | Automatique, toujours affichées, masquées ; taille réglable |
| Vibrations | Mobile |
| Aide des touches en jeu | Affiche ou masque le bandeau |
| Fantôme | Affiche le fantôme de ton meilleur temps |
| Mises à jour | Vérifie s'il existe une version plus récente (voir [vie privée](#sauvegarde-et-vie-privée)) |
| Effacer la sauvegarde | Records, succès, pièces, statistiques (double confirmation) |

**Accessibilité** (Options → *Accessibilité et touches*) :

- **Mode daltonien** : palette Okabe-Ito pour les dalles spéciales et symboles sur chaque dalle.
- **Symboles sur les dalles spéciales** (sans changer les couleurs).
- **Aide au saut** : temps de grâce doublé pour sauter après avoir quitté un bord ou avant de toucher le sol.
- **Taille du texte** : 80 % à 160 %.
- **Touches du clavier réassignables** (les flèches et la manette restent actives), avec un bouton de remise à zéro.

---

## Génération procédurale et seeds

Chaque étape dépend de `(seed de la run, monde, position dans la run, longueur, difficulté)` : **une même seed redonne exactement les mêmes parcours**. La seed est affichée en jeu ; une seed peut être un nombre ou un mot.

Le générateur ([scripts/generator.gd](scripts/generator.gd)) :

- adapte nombre de dalles (≈ 11 à 27, jusqu'à 90 en Marathon), taille des dalles, écarts maximum (jusqu'à 4,6 m) et fréquence des checkpoints à la difficulté du monde ;
- tire les types de plateformes selon le profil du monde (voir [level_data.gd](scripts/level_data.gd)) ;
- évite les enchaînements injustes : jamais deux clignotantes de suite, au plus 2 ou 3 dalles instables d'affilée, pas de canons ou tourniquets collés, trampoline et lanceur toujours suivis d'une dalle à portée ;
- crée les paires obligatoires (interrupteur → pont, portail → sortie) et l'arène des boss ;
- fait tourner le parcours sans chevauchement et place des bonus au-dessus de certains vides.

---

## Mobile

- **Android** : APK et AAB, paysage, commandes tactiles (joystick flottant, bouton de saut, glisser pour la caméra), vibrations, qualité basse par défaut, bouton « retour » géré, marges de sécurité pour les encoches. Voir [docs/ANDROID.md](docs/ANDROID.md).
- **Navigateur mobile** : la version Web détecte l'écran tactile et affiche les commandes.
- **iOS** : même code, mais l'export demande un Mac et un compte Apple (voir [docs/ANDROID.md](docs/ANDROID.md#5-ios-non-fourni)).

---

## Audio

Sons et musiques sont **synthétisés** par défaut. Pour utiliser tes propres fichiers (OGG, WAV, MP3), dépose-les dans `audio/music/` (une piste par monde, menu, histoire, jingles) et `audio/sfx/` avec les noms indiqués dans [audio/README.md](audio/README.md) : le jeu les prend automatiquement, piste par piste.

---

## Sauvegarde et vie privée

Fichiers dans le dossier utilisateur de Godot :

- Windows : `%APPDATA%\Godot\app_userdata\Diamant Rush 3D\` (`save.cfg`, `ghosts.dat`)
- Linux : `~/.local/share/godot/app_userdata/Diamant Rush 3D/`
- Android : stockage privé de l'application

Contenu : records, classement, statistiques, succès, défis réussis, modificateurs, options, fantômes.

**Réseau** : si l'option *Mises à jour* est activée (par défaut), le menu principal envoie **une seule requête HTTPS** vers `api.github.com` pour lire le numéro de la dernière Release ; GitHub voit l'adresse IP, comme pour toute requête web. Rien d'autre n'est envoyé. Désactive l'option pour ne faire aucune requête. Pas de publicité, pas de compte, pas de traceur.

---

## Structure du projet

```
project.godot            Configuration Godot (autoload Global, mobile, rendu)
export_presets.cfg       Presets : Windows, Linux, Web, macOS, Android APK, Android AAB
icon.svg                 Icône
audio/                   Musiques et sons optionnels (voir audio/README.md)
scenes/                  main_menu, story, level
scripts/
  global.gd              Autoload : run, modes, défis, codes, fantômes, classement, options, audio, sauvegarde
  generator.gd           Génération procédurale des parcours
  level_data.gd          Les 12 mondes (couleurs, difficulté, profil de pièges)
  level.gd               Construction d'une étape, HUD, pause, boss, fantôme, victoire / défaite
  player.gd              Lumi : mouvement, caméra, ombre, bonus, animations
  platform.gd            Dalles (16 types)
  projectile.gd, boss.gd Tirs des canons et boss de fin de monde
  ghost.gd               Fantôme du meilleur temps
  pickup.gd              Pièces, bonus, diamant
  decor.gd, fx.gd        Décors, accessoires, particules
  textures.gd, models.gd Textures et maillages générés par code
  sfx.gd                 Sons et musiques synthétisés
  story.gd               Textes de l'histoire (12 chapitres)
  translations.gd        Traductions anglaises
  achievements.gd        Succès
  update_check.gd        Vérification des mises à jour
  touch_controls.gd      Commandes tactiles
  main_menu.gd           Menus
  story_screen.gd        Écran d'histoire
tests/                   smoke.gd (fumée complète), bot.gd (robot joueur)
tools/                   build_all.sh / .ps1, make_keystore.sh, screenshots.gd
docs/                    ANDROID.md, MACOS_SIGNING.md, STORE_PAGE.md
.github/workflows/       CI : tests + exports + Release
```

### Ajouter un monde

1. Ajoute une entrée dans `get_themes()` de [level_data.gd](scripts/level_data.gd) (et augmente `WORLD_COUNT`).
2. Ajoute son chapitre dans [story.gd](scripts/story.gd), ses accessoires et paysage dans [decor.gd](scripts/decor.gd), ses particules dans [fx.gd](scripts/fx.gd), sa musique dans [sfx.gd](scripts/sfx.gd) et dans `MUSIC_FILES` de [global.gd](scripts/global.gd).
3. Ajoute les traductions dans [translations.gd](scripts/translations.gd).
4. Lance `tests/smoke.gd` et `tests/bot.gd`.

### Ajouter une langue

Dans [translations.gd](scripts/translations.gd), copie le dictionnaire `EN` sous un nouveau nom, traduis les valeurs, crée un `Translation` avec la bonne `locale` dans `build()`, puis ajoute la langue au sélecteur de [main_menu.gd](scripts/main_menu.gd) et à `apply_language()`. Les textes sans traduction restent en français.

---

## Tests

Tout se lance en ligne de commande, **sans fenêtre** (`--headless`). Remplace `godot` par le chemin de ton exécutable.

### Test de fumée

Vérifie le générateur (12 mondes × 4 longueurs × 3 difficultés), la construction des 12 mondes avec **tous** les modificateurs, le comportement de chaque nouveau piège (lanceur, portail, interrupteur/pont, canon, tapis, clignotante, orbitale, ascenseur), le boss (réveil, tirs, coups, défaite, diamant), le mode infini et le classement, les défis et codes de partage, le fantôme, les runs, succès, apparences, sauvegarde, remappage des touches, versions et traductions, les 11 pages de menu en français et en anglais, les commandes tactiles, la manette, l'accessibilité, l'ombre et la caméra anti-traversée.

```bash
godot --headless --path . --script tests/smoke.gd
```

Code de sortie 0 si tout passe.

### Robot joueur

Un robot joue réellement les étapes (physique incluse, esquive des tirs, portails, interrupteurs) pour vérifier qu'elles sont **franchissables** ; dans un monde à boss, il réussit s'il atteint l'arène :

```bash
godot --headless --path . --script tests/bot.gd -- 0 3        # seeds 0 à 2, 12 mondes chacune
BOTMODS="gravity=2,mirror,crumble,length=1" godot --headless --path . --script tests/bot.gd -- 0 2
```

`BOTMODS` accepte `speed`, `timer`, `hardcore`, `no_double`, `mirror`, `ice`, `wind`, `crumble`, `lava`, `fog`, `invert`, et `gravity=0|1|2`, `length=0..3`, `difficulty=0..2`. Le robot ne freine pas et ne sait pas jouer avec `invert` : certains échecs en vitesse x1.5 ou gravité lunaire viennent de ses limites, pas du niveau.

Les tests peuvent modifier ta sauvegarde : supprime `save.cfg` et `ghosts.dat` après les avoir lancés.

---

## Construire les versions (exe, apk, web…)

### Prérequis

Installe les **modèles d'exportation** de ta version de Godot (Éditeur → *Gérer les modèles d'exportation*). Les presets sont dans `export_presets.cfg`.

### Tout d'un coup

```bash
GODOT=/chemin/godot tools/build_all.sh windows linux web macos          # Linux / macOS / Git Bash
```

```powershell
.\tools\build_all.ps1 -Godot "C:\chemin\Godot_v4.3-stable_win64_console.exe"   # Windows
```

Les fichiers sont créés dans `build/` et zippés dans `dist/` (`DiamantRush3D-3.1.0-windows.zip`, `-linux`, `-web`, `-macos`, `-android.apk`).

| Cible | Résultat | Remarque |
|---|---|---|
| Windows | `.exe` unique (PCK intégré) | Pour changer l'icône de l'exe, installe `rcedit` et active `application/modify_resources` |
| Linux | `.x86_64` unique | |
| Web | `index.html` + `.wasm` + `.pck` | À servir par HTTP (pas en `file://`) ; sans threads, donc compatible partout |
| macOS | `.zip` contenant le `.app` | Non signé : clic droit → Ouvrir. Pour signer : [docs/MACOS_SIGNING.md](docs/MACOS_SIGNING.md) |
| Android | `.apk` / `.aab` | Clés et SDK nécessaires : [docs/ANDROID.md](docs/ANDROID.md) |

### Avec GitHub (CI)

Le workflow [.github/workflows/build.yml](.github/workflows/build.yml) lance les tests puis construit toutes les versions et les joint à une **Release** quand tu pousses un tag :

```bash
git tag v3.1.0 && git push origin v3.1.0
```

### Page de boutique

Textes (FR/EN), mots-clés et politique de confidentialité prêts à copier : [docs/STORE_PAGE.md](docs/STORE_PAGE.md). Captures d'écran : `godot --path . --script tools/screenshots.gd -- 1920 1080` (ouvre une fenêtre quelques secondes ; images dans `store/screenshots/`).

### Liste de contrôle avant publication

- [ ] `config/version` (`project.godot`), `Global.VERSION` (`scripts/global.gd`), versions des presets d'export à jour
- [ ] [CHANGELOG.md](CHANGELOG.md) à jour
- [ ] `tests/smoke.gd` et `tests/bot.gd` passent
- [ ] Chaque export a été lancé au moins une fois sur sa plateforme
- [ ] Pour Android : clé de publication créée et **sauvegardée**
- [ ] Tag git `vX.Y.Z` posé sur le commit de release

---

## Problèmes fréquents

- **Écran noir / erreur Vulkan (PC)** : carte graphique trop ancienne pour *Forward+*. Projet → Paramètres → Rendu → Moteur de rendu → *Compatibilité*.
- **Le jeu rame** : Options → Qualité *Basse*, désactive les ombres, baisse le FOV.
- **Plus de son** : vérifie les curseurs de volume ; sur navigateur, clique d'abord sur la page.
- **La souris ne bouge plus la caméra** : `Échap` (pause) puis *Reprendre*.
- **Les commandes tactiles n'apparaissent pas** : Options → Commandes tactiles → *Toujours affichées*.
- **Une touche ne répond plus** : Options → Accessibilité et touches → *Touches par défaut*.
- **Messages `mesh_get_surface_count` en test headless** : sans importance (rendu factice).
- **Export qui échoue sous Windows (« Safe save failed », « Impossible de décompresser l'APK »)** : antivirus qui verrouille les fichiers temporaires ; voir [docs/ANDROID.md](docs/ANDROID.md#3-exporter).

---

## Crédits

Conception, code, modèles, sons et musiques synthétisés : projet Diamant Rush 3D, développé avec l'aide de Claude (Anthropic). Moteur : [Godot Engine](https://godotengine.org) (licence MIT).
