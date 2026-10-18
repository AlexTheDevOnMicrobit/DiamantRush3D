# Changelog

## 2.0.0

### Nouveau
- **Mode run** : 5 étapes générées procéduralement (une par royaume), seed reproductible, run aléatoire / du jour / personnalisée.
- **Histoire** : introduction, texte avant et après chaque étape, fin de run, écran de victoire.
- **Assets entièrement générés** : robot Lumi animé (course, saut, chute, écrasement/étirement), dalles texturées avec pointes rocheuses, accessoires et paysages par royaume, particules, effets sonores et musique par royaume.
- **11 modificateurs** en plus de la gravité : vitesse, contre-la-montre, hardcore, sans double saut, miroir, glace, vent, dalles friables, lave qui montante, brouillard, commandes inversées. Chacun modifie le multiplicateur de score.
- **Options** : volumes (général, musique, effets), sensibilité souris, FOV, axe vertical inversé, plein écran, ombres, aide des touches.
- Outils de test : `tests/smoke.gd` et `tests/bot.gd` (robot qui joue les parcours).
- Fichiers de sortie : README complet, licence MIT, icône, presets d'export Windows / Linux / Web.

### Corrigé / ajusté
- Le saut est désormais de même hauteur quelle que soit la gravité (seule la durée en l'air change), pour que la gravité lourde ne rende pas des écarts impossibles.
- Relâcher `Espace` ne raccourcit plus un rebond de trampoline.
- Le vent ne pousse plus fortement un joueur immobile au sol.
- Dalles friables en mode « dalles friables » : délai augmenté à 0,8 s pour rester jouable.

## 1.0.0

- Version initiale : 5 niveaux fixes, menu, double saut, modificateurs de gravité, sauvegarde des records.
