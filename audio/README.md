# Audio

Dépose ici tes fichiers audio : le jeu les utilise automatiquement à la place des sons et musiques synthétisés.
Les pistes absentes gardent leur version synthétisée, tu peux donc les ajouter une par une, sans toucher au code.

Pour voir ce qui est déjà fourni et ce qui manque :

```bash
godot --headless --path . --script tools/check_audio.gd
```

(Affiche pour chaque effet sa durée, le silence final retiré et le gain automatique appliqué.)

## Règles générales

- **Format** : OGG Vorbis conseillé (léger : mobile et Web). WAV et MP3 acceptés. Les doubles extensions (`jump.ogg.wav`) sont acceptées aussi.
- **Noms** : exactement ceux des tableaux ci-dessous, sans accent ni espace.
- **Effets sonores** : le jeu **retire automatiquement le silence de fin** et **égalise le volume** de chaque effet (gain de -12 à +18 dB visant une crête à 70 %). Tu peux donc livrer des fichiers de longueur fixe ou assez discrets ; évite seulement d'écrêter (crête à 100 % déformée).
- **Boucles musicales** : elles doivent se raccorder sans silence ni fondu (la fin enchaîne le début).
- **Jingles** : pas de boucle ; ils jouent une fois.
- Pense à créditer les auteurs dans le README du projet.

## Musique : `audio/music/`

| Fichier | Où | Boucle | Ambiance suggérée (tempo / tonalité du son synthétisé) |
|---|---|---|---|
| `menu` | Menu principal | oui | Calme, mystérieuse |
| `story` | Écrans d'histoire | oui | Douce, narrative, lente |
| `boss` | Combats de boss (remplace la musique du monde le temps du combat) | oui | Tendue, rythmée, 120-140 BPM |
| `world_01_prairies` | Prairies Suspendues | oui | Légère, joyeuse (~90 BPM) |
| `world_02_foret` | Forêt des Murmures | oui | Mystérieuse, boisée (~75 BPM) |
| `world_03_dunes` | Dunes d'Ambre | oui | Chaude, orientale (~88 BPM) |
| `world_04_recif` | Récif Céleste | oui | Aérienne, cordes pincées (~100 BPM) |
| `world_05_toundra` | Toundra de Givre | oui | Froide, cristalline (~68 BPM) |
| `world_06_cristaux` | Grotte des Cristaux | oui | Éthérée, mystique (~83 BPM) |
| `world_07_usine` | Usine d'Engrenages | oui | Mécanique, percussive (~115 BPM) |
| `world_08_ruines` | Ruines Dorées | oui | Antique, solennelle (~80 BPM) |
| `world_09_marais` | Marais Spectral | oui | Inquiétante, lente, ambiante (~62 BPM) |
| `world_10_volcan` | Volcan Endormi | oui | Lourde, tendue (~105 BPM) |
| `world_11_neon` | Cité Néon | oui | Synthwave rapide (~125 BPM) |
| `world_12_ciel` | Ciel Infini | oui | Épique, cosmique (~70 BPM) |
| `world_13_abysses` | Abysses Lumineuses (monde secret) | oui | Aquatique, onirique, bulles et cloches (~70 BPM) |
| `world_14_sucreries` | Pays des Sucreries (monde secret) | oui | Joyeuse, boîte à musique, sautillante (~110 BPM) |
| `world_15_forteresse` | Forteresse de l'Ombre (monde secret) | oui | Sombre, orgue et cordes graves, menaçante (~90 BPM) |
| `win` | Étape terminée | non (2 à 6 s) | Petite fanfare |
| `lose` | Run perdue (accepte aussi `loose`) | non (2 à 4 s) | Mélodie descendante douce |
| `run_complete` | Fin de l'Aventure / Run éclair | non (10 à 15 s) | Triomphale |

## Effets sonores : `audio/sfx/`

| Fichier | Quand | Durée | Caractère |
|---|---|---|---|
| `jump` | Saut | 0,15-0,25 s | Léger, montant |
| `jump2` | Double saut | 0,15-0,25 s | Plus aigu et aérien |
| `land` | Atterrissage après une chute (aussi : impact des météores du boss, plus grave) | 0,1-0,2 s | Choc sourd |
| `coin` | Pièce | 0,2-0,4 s | Tintement brillant |
| `bounce` | Trampoline | 0,3 s | « Boing » montant |
| `launch` | Lanceur directionnel | 0,25 s | Souffle qui monte vite |
| `checkpoint` | Checkpoint, interrupteur (hauteur x1,3), bonus (x1,5) | 0,4-0,6 s | Petit arpège de 3 notes |
| `fall` | Chute dans le vide | 0,5-0,8 s | Glissando descendant |
| `crumble` | Dalle friable qui tremble | 0,3-0,4 s | Craquement, bruité |
| `hit` | Lumi touché | 0,2-0,3 s | Impact net |
| `cannon` | Tir de canon | 0,2-0,3 s | « Poum » sourd |
| `portal` | Entrée dans un portail | 0,3-0,5 s | Whoosh qui monte puis descend |
| `boost` | Bonus de vitesse | 0,3 s | Montée énergique |
| `wing` | Bonus d'ailes | 0,3-0,4 s | Battement d'ailes léger |
| `achievement` | Succès débloqué | 0,5-0,8 s | Petite fanfare gratifiante |
| `click` | Bouton de menu | 0,05-0,08 s | Clic court |
| `bumper` | Rebond sur un bumper (**nouveau en 3.2**) | 0,15-0,25 s | « Pop » élastique, un peu flipper |
| `star` | Étoile gagnée à la fin d'une étape (**nouveau**) | 0,3-0,5 s | Carillon brillant montant |
| `boss_wake` | Réveil du boss (**nouveau**) | 0,8-1,2 s | Grondement grave |
| `boss_shot` | Tir ou balayage du boss (**nouveau**) | 0,2 s | Tir plus menaçant que `cannon` |
| `boss_beam` | Rayon rotatif du boss (**nouveau**) | 0,8-1,0 s | Charge d'énergie qui monte |
| `equip` | Choix d'une apparence, d'un chapeau, d'une traînée (**nouveau**) | 0,15 s | Petit « ding » doux |
| `streak` | Série de défis quotidiens (**nouveau**) | 0,5 s | Petite montée de 4 notes |
| `tip` | Astuce sur un nouveau piège (**nouveau**) | 0,15 s | Deux petites notes discrètes |
