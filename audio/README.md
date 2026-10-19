# Audio

Dépose ici tes fichiers audio : le jeu les utilise automatiquement à la place des sons et musiques synthétisés.
Les pistes absentes gardent leur version synthétisée, tu peux donc les ajouter une par une.

## Musique : `audio/music/`

Format conseillé : OGG Vorbis, stéréo, 44,1 kHz, qualité 5-6. Les boucles doivent se raccorder sans silence.
Noms exacts (extension `.ogg`, `.wav` ou `.mp3`) :

| Fichier | Où | Boucle |
|---|---|---|
| `menu` | Menu principal | oui |
| `story` | Écrans d'histoire | oui |
| `world_01_prairies` ... `world_12_ciel` | Les 12 mondes (voir `scripts/global.gd`, `MUSIC_FILES`) | oui |
| `win` | Étape terminée | non (2 à 6 s) |
| `lose` | Run perdue | non (2 à 6 s) |
| `run_complete` | Fin de l'Aventure / Run éclair | non (10 à 15 s) |

## Effets sonores : `audio/sfx/`

Noms des fichiers (`.ogg` ou `.wav`, courts) : `jump`, `jump2`, `coin`, `bounce`, `land`, `checkpoint`, `fall`, `crumble`,
`click`, `boost`, `wing`, `achievement`, `hit`, `portal`, `launch`, `cannon`.

Aucun redémarrage de code n'est nécessaire : relance simplement le jeu. Pense à créditer les auteurs dans le README.
