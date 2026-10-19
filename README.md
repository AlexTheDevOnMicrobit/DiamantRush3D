# Diamant Rush 3D

Platformeur 3D low-poly réalisé avec **Godot 4.3**. Tu incarnes **Lumi**, un petit robot gardien de phare, et tu traverses les douze mondes d'un royaume flottant pour retrouver les éclats du Grand Diamant.

Tout est généré par code : **aucun asset externe** (modèles, textures, sons, musiques, particules).

- Version : **3.0.0** (voir [CHANGELOG.md](CHANGELOG.md))
- Plateformes : Windows, Linux, macOS, Web, **Android** (et iOS avec un Mac)
- Contrôles : clavier / souris, manette, écran tactile
- Langue du jeu : français
- Licence : MIT ([LICENSE](LICENSE))

---

## Sommaire

1. [Installation et lancement](#installation-et-lancement)
2. [Modes de jeu](#modes-de-jeu)
3. [Les 12 mondes](#les-12-mondes)
4. [Commandes](#commandes)
5. [Plateformes et bonus](#plateformes-et-bonus)
6. [Modificateurs](#modificateurs)
7. [Score, succès, apparences](#score-succès-apparences)
8. [Options](#options)
9. [Génération procédurale et seeds](#génération-procédurale-et-seeds)
10. [Mobile](#mobile)
11. [Sauvegarde](#sauvegarde)
12. [Structure du projet](#structure-du-projet)
13. [Tests](#tests)
14. [Construire les versions (exe, apk, web…)](#construire-les-versions-exe-apk-web)
15. [Problèmes fréquents](#problèmes-fréquents)

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
| **Aventure** | Les 12 mondes dans l'ordre, de plus en plus difficiles, avec toute l'histoire. |
| **Run éclair** | 5 mondes tirés selon la seed (un par palier de difficulté). Dure moins longtemps. |
| **Run du jour** | Run éclair avec la seed du jour (`AAAAMMJJ`), identique pour tous. |
| **Monde libre** | Un seul monde au choix pour s'entraîner. |

Chaque run : tombe dans le vide et tu réapparais au dernier **checkpoint** ; ramasse les pièces ; touche le **diamant** pour finir l'étape. Une run se termine à la fin du dernier monde, ou plus tôt avec le mode Hardcore / Contre-la-montre.

---

## Les 12 mondes

Chaque monde a ses couleurs, sa musique, ses décors, ses particules et sa **difficulté propre** (étoiles).

| # | Monde | Difficulté | Particularité |
|---|---|---|---|
| 1 | Prairies Suspendues | ★☆☆☆☆ | Tranquille : plateformes simples |
| 2 | Forêt des Murmures | ★☆☆☆☆ | Dalles clignotantes, ascenseurs |
| 3 | Dunes d'Ambre | ★★☆☆☆ | Dalles friables, tapis roulants |
| 4 | Récif Céleste | ★★☆☆☆ | Plateformes orbitales, trampolines |
| 5 | Toundra de Givre | ★★☆☆☆ | **Sol glissant** en permanence |
| 6 | Grotte des Cristaux | ★★★☆☆ | Tourniquets, clignotantes |
| 7 | Usine d'Engrenages | ★★★☆☆ | Tapis roulants, ascenseurs, pistons |
| 8 | Ruines Dorées | ★★★☆☆ | Dalles qui s'effondrent, clignotantes |
| 9 | Marais Spectral | ★★★★☆ | **Vent** permanent, brouillard dense |
| 10 | Volcan Endormi | ★★★★☆ | Tout en même temps |
| 11 | Cité Néon | ★★★★★ | Rapide et dense en pièges |
| 12 | Ciel Infini | ★★★★★ | Petites dalles, tous les pièges |

---

## Commandes

| Action | Clavier / souris | Manette | Mobile |
|---|---|---|---|
| Bouger | `W A S D` / `Z Q S D` / flèches | Stick gauche | Joystick à gauche |
| Sauter / double saut | `Espace` | `A` | Bouton **SAUT** |
| Caméra | Souris | Stick droit | Glisser à droite |
| Pause | `Échap` ou `P` | `Start` | Bouton pause, bouton « retour » Android |
| Recommencer l'étape | `R` | `Y` | via le menu pause |

Les touches clavier sont reconnues par position physique : WASD fonctionne pareil en QWERTY et en AZERTY. Relâcher le saut plus tôt donne un saut plus court.

---

## Plateformes et bonus

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

## Score, succès, apparences

Score d'une étape :

```
(1000 + 150 × pièces + 10 × secondes de marge sur le temps de référence) × multiplicateur
```

Fin d'Aventure / Run éclair : **bonus de 1000 × multiplicateur**. Les meilleurs scores (Aventure, Éclair, chaque monde libre) sont sauvegardés.

- **16 succès** (écran *Succès et statistiques*) : sans chute, toutes les pièces, marathon, Hardcore, run du jour, les 12 mondes, etc. Une annonce apparaît en jeu et à la fin de l'étape.
- **8 apparences de Lumi** (écran *Apparences*), débloquées avec le total de pièces ramassées : Orange, Bleu, Vert, Rose, Violet, Or, Ombre, Arc-en-ciel.
- **Statistiques** : temps de jeu, étapes et runs terminées, pièces, sauts, chutes, mondes terminés.

---

## Options

| Option | Rôle |
|---|---|
| Volumes (général, musique, effets) | 0 à 100 % |
| Sensibilité caméra, FOV, axe vertical inversé | Caméra |
| **Qualité** | Basse / Moyenne / Élevée (anticrénelage, ombres, lueur, nombre de décors et de particules). Basse par défaut sur mobile. |
| Ombres, plein écran | Ordinateur |
| Commandes tactiles | Automatique, toujours affichées, masquées ; taille réglable |
| Vibrations | Mobile |
| Aide des touches en jeu | Affiche ou masque le bandeau |
| Effacer la sauvegarde | Records, succès, pièces, statistiques (double confirmation) |

---

## Génération procédurale et seeds

Chaque étape dépend de `(seed de la run, monde, position dans la run, longueur, difficulté)` : **une même seed redonne exactement les mêmes parcours**. La seed est affichée en jeu ; une seed peut être un nombre ou un mot.

Le générateur ([scripts/generator.gd](scripts/generator.gd)) :

- adapte nombre de dalles (≈ 11 à 27, jusqu'à 90 en Marathon), taille des dalles, écarts maximum (jusqu'à 4,6 m) et fréquence des checkpoints à la difficulté du monde ;
- tire les types de plateformes selon le profil du monde (voir [level_data.gd](scripts/level_data.gd)) ;
- évite les enchaînements injustes : jamais deux clignotantes de suite, au plus 2 ou 3 dalles instables d'affilée, trampoline toujours suivi d'une dalle haute à portée ;
- fait tourner le parcours sans chevauchement et place des bonus au-dessus de certains vides.

---

## Mobile

- **Android** : APK et AAB, paysage, commandes tactiles (joystick flottant, bouton de saut, glisser pour la caméra), vibrations, qualité basse par défaut, bouton « retour » géré, marges de sécurité pour les encoches. Voir [docs/ANDROID.md](docs/ANDROID.md).
- **Navigateur mobile** : la version Web détecte l'écran tactile et affiche les commandes.
- **iOS** : même code, mais l'export demande un Mac et un compte Apple (voir [docs/ANDROID.md](docs/ANDROID.md#5-ios-non-fourni)).

---

## Sauvegarde

Fichier `save.cfg` dans le dossier utilisateur de Godot :

- Windows : `%APPDATA%\Godot\app_userdata\Diamant Rush 3D\save.cfg`
- Linux : `~/.local/share/godot/app_userdata/Diamant Rush 3D/save.cfg`
- Android : stockage privé de l'application

Contenu : records, statistiques, succès, modificateurs et options.

---

## Structure du projet

```
project.godot            Configuration Godot (autoload Global, mobile, rendu)
export_presets.cfg       Presets : Windows, Linux, Web, macOS, Android APK, Android AAB
icon.svg                 Icône
scenes/                  main_menu, story, level
scripts/
  global.gd              Autoload : run, modes, options, modificateurs, succès, apparences, audio, sauvegarde
  generator.gd           Génération procédurale des parcours
  level_data.gd          Les 12 mondes (couleurs, difficulté, profil de pièges)
  level.gd               Construction d'une étape, HUD, pause, victoire / défaite, annonces
  player.gd              Lumi : mouvement, caméra, bonus, animations
  platform.gd            Dalles (10 types)
  pickup.gd              Pièces, bonus, diamant
  decor.gd, fx.gd        Décors, accessoires, particules
  textures.gd, models.gd Textures et maillages générés par code
  sfx.gd                 Sons et musiques synthétisés (une musique par monde)
  story.gd               Textes de l'histoire (12 chapitres)
  achievements.gd        Succès
  touch_controls.gd      Commandes tactiles
  main_menu.gd           Menus (run, mondes, modificateurs, options, succès, apparences…)
  story_screen.gd        Écran d'histoire
tests/                   smoke.gd (fumée complète), bot.gd (robot joueur)
tools/                   build_all.sh / .ps1, make_keystore.sh
docs/ANDROID.md          Guide Android
.github/workflows/       CI : tests + exports + Release
```

### Ajouter un monde

1. Ajoute une entrée dans `get_themes()` de [level_data.gd](scripts/level_data.gd) (et augmente `WORLD_COUNT`).
2. Ajoute son chapitre dans [story.gd](scripts/story.gd), ses accessoires et paysage dans [decor.gd](scripts/decor.gd), ses particules dans [fx.gd](scripts/fx.gd) et sa musique dans [sfx.gd](scripts/sfx.gd).
3. Lance `tests/smoke.gd` et `tests/bot.gd`.

---

## Tests

Tout se lance en ligne de commande, **sans fenêtre** (`--headless`). Remplace `godot` par le chemin de ton exécutable.

### Test de fumée

Vérifie : le générateur (12 mondes × 4 longueurs × 3 difficultés), la construction des 12 mondes avec **tous** les modificateurs, chute / pause / victoire, les runs Aventure / Éclair / Monde libre, les succès, apparences, la sauvegarde, les 9 pages de menu, les commandes tactiles et la manette.

```bash
godot --headless --path . --script tests/smoke.gd
```

Code de sortie 0 si tout passe.

### Robot joueur

Un robot joue réellement les étapes (physique incluse) pour vérifier qu'elles sont **franchissables** :

```bash
godot --headless --path . --script tests/bot.gd -- 0 3        # seeds 0 à 2, 12 mondes chacune
BOTMODS="gravity=2,mirror,crumble,length=1" godot --headless --path . --script tests/bot.gd -- 0 2
```

`BOTMODS` accepte `speed`, `timer`, `hardcore`, `no_double`, `mirror`, `ice`, `wind`, `crumble`, `lava`, `fog`, `invert`, et `gravity=0|1|2`, `length=0..3`, `difficulty=0..2`. Le robot ne freine pas et ne sait pas jouer avec `invert` : certains échecs en vitesse x1.5 ou gravité lunaire viennent de ses limites, pas du niveau.

Les tests peuvent modifier ta sauvegarde : supprime `save.cfg` après les avoir lancés.

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

Les fichiers sont créés dans `build/` et zippés dans `dist/` (`DiamantRush3D-3.0.0-windows.zip`, `-linux`, `-web`, `-macos`, `-android.apk`).

| Cible | Résultat | Remarque |
|---|---|---|
| Windows | `.exe` unique (PCK intégré) | Pour changer l'icône de l'exe, installe `rcedit` et active `application/modify_resources` |
| Linux | `.x86_64` unique | |
| Web | `index.html` + `.wasm` + `.pck` | À servir par HTTP (pas en `file://`) ; sans threads, donc compatible partout |
| macOS | `.zip` contenant le `.app` | Non signé : clic droit → Ouvrir. Signature / notarisation à configurer pour une diffusion large |
| Android | `.apk` / `.aab` | Clés et SDK nécessaires : [docs/ANDROID.md](docs/ANDROID.md) |

### Avec GitHub (CI)

Le workflow [.github/workflows/build.yml](.github/workflows/build.yml) lance les tests puis construit toutes les versions et les joint à une **Release** quand tu pousses un tag :

```bash
git tag v3.0.0 && git push origin v3.0.0
```

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
- **Messages `mesh_get_surface_count` en test headless** : sans importance (rendu factice).
- **Export Android en `--headless` sous Windows** : voir [docs/ANDROID.md](docs/ANDROID.md).

---

## Crédits

Conception, code, modèles, sons et musiques : projet Diamant Rush 3D, développé avec l'aide de Claude (Anthropic). Moteur : [Godot Engine](https://godotengine.org) (licence MIT).
