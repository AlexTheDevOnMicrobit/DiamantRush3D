# Diamant Rush 3D

Platformeur 3D low-poly réalisé avec **Godot 4.3**. Tu incarnes **Lumi**, un petit robot gardien de phare, et tu traverses cinq royaumes flottants pour retrouver les cinq éclats du Grand Diamant.

Tout est généré par code : **aucun asset externe** (modèles, textures, sons, musiques, particules).

- Version : **2.0.0** (voir [CHANGELOG.md](CHANGELOG.md))
- Licence : MIT (voir [LICENSE](LICENSE))
- Langue du jeu : français

---

## Sommaire

1. [Installation et lancement](#installation-et-lancement)
2. [Principe du jeu](#principe-du-jeu)
3. [Commandes](#commandes)
4. [Les cinq royaumes](#les-cinq-royaumes)
5. [Types de plateformes](#types-de-plateformes)
6. [Modificateurs](#modificateurs)
7. [Score](#score)
8. [Options](#options)
9. [Génération procédurale et seeds](#génération-procédurale-et-seeds)
10. [Sauvegarde](#sauvegarde)
11. [Structure du projet](#structure-du-projet)
12. [Tests](#tests)
13. [Exporter le jeu (release)](#exporter-le-jeu-release)
14. [Problèmes fréquents](#problèmes-fréquents)

---

## Installation et lancement

### Depuis les sources

1. Installe **Godot 4.3 ou plus récent** (version standard, pas .NET) : <https://godotengine.org/download>.
2. Ouvre Godot, clique sur **Importer** et choisis le fichier `project.godot` de ce dossier.
3. Lance le jeu avec **F5**.

Le moteur de rendu utilisé est *Forward+* (carte graphique compatible Vulkan). Sur une machine plus ancienne, désactive les ombres dans les Options du jeu.

### Depuis une version exportée

Voir [Exporter le jeu](#exporter-le-jeu-release). Le jeu exporté est un exécutable unique (`.exe` sous Windows, `.x86_64` sous Linux) ou une page web.

---

## Principe du jeu

Une **run** se compose de **5 étapes**, une par royaume. Chaque étape est un parcours de plateformes **généré aléatoirement** qui se termine par un **diamant** à toucher. Les étapes sont de plus en plus longues et difficiles.

- Tombe dans le vide : tu réapparais au dernier **checkpoint** (dalle bleue devenue verte).
- Ramasse les **pièces dorées** pour augmenter ton score.
- Finis les 5 étapes pour reconstituer le Grand Diamant et terminer la run.
- Une histoire accompagne chaque étape (écran de texte avant l'étape, phrase de conclusion après).

Menu principal :

| Entrée | Rôle |
|---|---|
| Nouvelle run | Run aléatoire, run du jour, ou seed personnalisée |
| Modificateurs | Change les règles du jeu (et le multiplicateur de score) |
| Options | Volumes, souris, FOV, plein écran, ombres… |
| Histoire | Relire l'introduction |
| Commandes | Rappel des touches |

---

## Commandes

| Action | Touches |
|---|---|
| Se déplacer | `W A S D` ou `Z Q S D` (clavier AZERTY) ou flèches |
| Sauter | `Espace` (appuie à nouveau en l'air pour le **double saut**) |
| Saut plus court | Relâcher `Espace` tôt |
| Caméra | Souris |
| Pause | `Échap` ou `P` |
| Recommencer l'étape | `R` |

Les touches sont reconnues par position physique : les mêmes quatre touches fonctionnent en QWERTY et en AZERTY.

---

## Les cinq royaumes

| # | Royaume | Ambiance | Spécialité |
|---|---|---|---|
| 1 | Prairies Suspendues | Ciel bleu, arbres, pétales | Plateformes simples, quelques mobiles |
| 2 | Dunes d'Ambre | Sable, pyramides, soleil orange | Beaucoup de dalles qui s'effondrent |
| 3 | Grotte des Cristaux | Cristaux lumineux, lucioles | Tourniquets et trampolines |
| 4 | Volcan Endormi | Mer de lave, braises | Mélange dangereux de tout |
| 5 | Ciel Infini | Étoiles, planètes | Petites dalles, tous les pièges |

---

## Types de plateformes

| Couleur du dessus | Type | Comportement |
|---|---|---|
| Couleur du royaume | Normale | Solide |
| Bleu clair → vert | Checkpoint | Devient ton point de réapparition |
| Bleu vif | Mobile | Va et vient latéralement |
| Orange | Friable | Tremble puis tombe après un court instant, réapparaît plus tard |
| Rose lumineux | Trampoline | Te propulse très haut (le diamant et la dalle suivante sont plus hauts) |
| Barre rouge | Tourniquet | Une barre tournante te pousse hors de la dalle : saute par-dessus |

---

## Modificateurs

Réglables dans **Modificateurs** (menu principal ou menu de nouvelle run). Ils se cumulent et multiplient le score.

| Modificateur | Effet | Multiplicateur |
|---|---|---|
| Gravité lunaire | Sauts longs et flottants (même hauteur de saut) | x0.8 |
| Gravité lourde | Chute rapide, sauts courts en distance | x1.4 |
| Vitesse x1.5 | Tout va plus vite | x1.25 |
| Contre-la-montre | Temps limité par étape (selon sa longueur) | x1.2 |
| Hardcore | Une chute = fin de la run | x1.8 |
| Sans double saut | Un seul saut | x1.5 |
| Niveaux en miroir | Parcours inversé gauche/droite | x1.1 |
| Sol glissant | Accélération et freinage très faibles au sol | x1.2 |
| Vent changeant | Un vent de direction et force variables te pousse en l'air | x1.2 |
| Dalles friables | Toutes les dalles normales s'effondrent | x1.4 |
| Lave qui monte | Une lave monte lentement, il faut avancer | x1.5 |
| Brouillard épais | Visibilité très réduite | x1.15 |
| Commandes inversées | Les directions sont inversées | x1.3 |

Un bouton **Aléatoire** tire des modificateurs au hasard, **Réinitialiser** remet tout à zéro.

> Certaines combinaisons extrêmes (par exemple gravité lourde + sans double saut + vitesse) sont volontairement très difficiles.

---

## Score

Score d'une étape :

```
(1000 + 150 × pièces + 10 × secondes de marge sur le temps de référence) × multiplicateur
```

À la fin de la 5ᵉ étape, un **bonus de 1000 × multiplicateur** est ajouté. Le meilleur score de run et son temps sont sauvegardés.

---

## Options

| Option | Rôle |
|---|---|
| Volume général / musique / effets | Curseurs de 0 à 100 % |
| Sensibilité souris | De 0.3x à 3x |
| Champ de vision (FOV) | 60° à 110° |
| Inverser l'axe vertical | Pour la caméra |
| Plein écran | Bascule fenêtre / plein écran |
| Ombres | À désactiver sur machine modeste |
| Aide des touches en jeu | Affiche ou masque le bandeau d'aide |

---

## Génération procédurale et seeds

Chaque étape est calculée à partir de `(seed de la run, numéro d'étape)` : **une même seed redonne exactement les mêmes parcours**, ce qui permet de comparer des scores ou de rejouer une run.

- **Run aléatoire** : seed tirée au hasard (affichée en haut à droite en jeu).
- **Run du jour** : seed = date du jour (`AAAAMMJJ`), identique pour tous les joueurs.
- **Seed personnalisée** : un nombre, ou un mot (converti en nombre).

Le générateur ([scripts/generator.gd](scripts/generator.gd)) :

- limite les écarts entre dalles à 4,5 m et les réduit quand la dalle suivante est plus haute ;
- place un checkpoint toutes les cinq dalles ;
- garantit que chaque trampoline est suivi d'une dalle plus haute à portée ;
- fait tourner le parcours et rejette les dalles qui chevaucheraient une partie déjà construite ;
- adapte taille des dalles, longueur (13 à 25 dalles) et pièges au royaume.

---

## Sauvegarde

Fichier `save.cfg` dans le dossier utilisateur de Godot :

- Windows : `%APPDATA%\Godot\app_userdata\Diamant Rush 3D\save.cfg`
- Linux : `~/.local/share/godot/app_userdata/Diamant Rush 3D/save.cfg`

Il contient : meilleur score et temps de run, nombre de runs terminées, étape la plus loin atteinte, modificateurs choisis et options. Supprime le fichier pour tout réinitialiser.

---

## Structure du projet

```
project.godot            Configuration Godot (autoload Global, scène de démarrage)
export_presets.cfg       Presets d'export Windows / Linux / Web
icon.svg                 Icône du jeu
scenes/
  main_menu.tscn         Menu principal
  story.tscn             Écran d'histoire
  level.tscn             Étape de jeu
scripts/
  global.gd              Autoload : run, sauvegarde, options, modificateurs, audio
  generator.gd           Génération procédurale des parcours
  level_data.gd          Thèmes des 5 royaumes
  level.gd               Construction d'une étape, HUD, pause, victoire / défaite
  player.gd              Lumi : mouvement, caméra, animations
  platform.gd            Dalles (normale, mobile, friable, checkpoint, trampoline, tourniquet)
  pickup.gd              Pièces et diamant
  decor.gd               Accessoires de dalles et paysages par royaume
  fx.gd                  Particules
  textures.gd            Textures procédurales
  models.gd              Mesh du diamant, matériaux
  sfx.gd                 Synthèse des sons et musiques
  story.gd               Textes de l'histoire
  main_menu.gd           Menus (run, modificateurs, options…)
  story_screen.gd        Écran d'histoire avec texte progressif
  ui.gd, overlay.gd      Aides d'interface
tests/
  bot.gd                 Robot qui joue les étapes générées
  smoke.gd               Test de fumée complet
```

### Ajouter ou modifier un royaume

Les thèmes (couleurs, brouillard, poids des types de plateformes) sont dans [scripts/level_data.gd](scripts/level_data.gd). Les décors et accessoires sont dans [scripts/decor.gd](scripts/decor.gd), les particules d'ambiance dans [scripts/fx.gd](scripts/fx.gd), la musique dans [scripts/sfx.gd](scripts/sfx.gd).

---

## Tests

Les tests se lancent en ligne de commande, sans fenêtre. Remplace `godot` par le chemin de ton exécutable Godot.

### Test de fumée

Génère 1 500 parcours (300 seeds × 5 étapes), charge les 5 étapes avec **tous** les modificateurs activés (chute, pause, victoire) puis déroule une run complète jusqu'à l'écran de fin :

```bash
godot --headless --path . --script tests/smoke.gd
```

### Robot joueur

Un robot joue réellement les étapes (physique incluse) et vérifie qu'elles sont **franchissables** :

```bash
godot --headless --path . --script tests/bot.gd -- 0 5
```

Arguments : `<seed_début> <seed_fin>` (5 étapes par seed). Pour tester avec des modificateurs :

```bash
BOTMODS="gravity=2,mirror,crumble" godot --headless --path . --script tests/bot.gd -- 0 5
```

(`gravity=0|1|2`, ou n'importe quelle clé : `speed`, `timer`, `hardcore`, `no_double`, `mirror`, `ice`, `wind`, `crumble`, `lava`, `fog`.)

Le robot ne freine pas et ne sait pas jouer avec `invert` : les échecs en vitesse x1.5 ou gravité lunaire viennent surtout de ses limites (dépassement des petites dalles), pas forcément du niveau.

Les tests peuvent modifier ta sauvegarde : supprime `save.cfg` après les avoir lancés (voir [Sauvegarde](#sauvegarde)).

---

## Exporter le jeu (release)

1. Dans Godot : **Éditeur → Gérer les modèles d'exportation**, puis installe les modèles de ta version (4.3).
2. **Projet → Exporter…** : trois presets sont fournis (`Windows Desktop`, `Linux`, `Web`).
3. Clique sur **Exporter le projet** pour chacun. Les fichiers sont écrits dans `build/` (ignoré par git).

En ligne de commande :

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/DiamantRush3D.exe
godot --headless --path . --export-release "Linux" build/linux/DiamantRush3D.x86_64
godot --headless --path . --export-release "Web" build/web/index.html
```

Pour la version Web, sers le dossier `build/web/` avec un serveur HTTP (le jeu ne fonctionne pas en ouvrant directement le fichier). Les dossiers `tests/` et les fichiers Markdown sont exclus des exports.

### Liste de contrôle avant publication

- [ ] `config/version` dans `project.godot` et `Global.VERSION` dans `scripts/global.gd` à jour
- [ ] `CHANGELOG.md` mis à jour
- [ ] `tests/smoke.gd` et `tests/bot.gd` passent
- [ ] Un export de chaque plateforme visée a été lancé au moins une fois
- [ ] Un tag git `vX.Y.Z` posé sur le commit de release

---

## Problèmes fréquents

- **Écran noir / erreur Vulkan** : carte graphique trop ancienne pour *Forward+*. Dans `project.godot`, utilise le moteur *Compatibilité* (Projet → Paramètres → Rendu → Moteur de rendu).
- **Le jeu rame** : désactive les ombres (Options) et baisse le FOV.
- **Plus de son** : vérifie les curseurs de volume dans Options.
- **La souris ne bouge plus la caméra** : appuie sur `Échap` (pause) puis sur *Reprendre*.
- **Les messages `mesh_get_surface_count` en test headless** : sans importance, c'est le rendu factice de Godot.

---

## Crédits

Conception, code, modèles, sons et musiques : projet Diamant Rush 3D, développé avec l'aide de Claude (Anthropic). Moteur : [Godot Engine](https://godotengine.org) (licence MIT).
