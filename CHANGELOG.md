# Changelog

## 3.0.0

### Nouveau
- **12 mondes** (au lieu de 5), chacun avec sa difficulté (1 à 10), ses couleurs, ses décors, ses accessoires, ses particules, sa musique et son chapitre d'histoire : Prairies Suspendues, Forêt des Murmures, Dunes d'Ambre, Récif Céleste, Toundra de Givre (sol glissant), Grotte des Cristaux, Usine d'Engrenages, Ruines Dorées, Marais Spectral (vent), Volcan Endormi, Cité Néon, Ciel Infini.
- **Modes** : Aventure (12 mondes), Run éclair (5 mondes tirés selon la seed), Run du jour, Monde libre.
- **Modificateur Longueur** (x1,5 / x2 / x3, jusqu'à 90 plateformes) et **modificateur Difficulté** (Détendu / Normal / Expert).
- **4 nouveaux types de plateformes** : clignotante, tapis roulant, orbitale, ascenseur (10 types au total).
- **Bonus** : flèche de vitesse et ailes (saut supplémentaire).
- **16 succès**, **8 apparences** de Lumi (déblocage par pièces), statistiques détaillées, records par mode.
- **Mobile** : commandes tactiles (joystick flottant, bouton de saut, caméra au doigt, pause), orientation paysage, rendu Compatibilité, qualité graphique réglable (Basse par défaut sur mobile), vibrations, bouton « retour » Android, marges de sécurité, menus défilants.
- **Manette** : stick gauche, stick droit pour la caméra, A, Start, Y.
- Bannière de début d'étape avec la difficulté du monde ; annonces de succès en jeu.
- **Prêt pour la sortie** : presets d'export Windows, Linux, Web, macOS, Android (APK et AAB), scripts `tools/build_all.sh` / `.ps1`, création de keystore, CI GitHub (tests, exports, Release), guide `docs/ANDROID.md`, README complet.

### Corrigé / ajusté
- Le générateur n'enchaîne plus deux dalles clignotantes.
- Le robot de test (`tests/bot.gd`) joue les 12 mondes et tous les types de plateformes (≈ 99 % de réussite sans modificateur).

### Vérifié
- Exports Windows, Linux, Web et macOS construits avec les modèles officiels 4.3 ; l'exécutable Windows démarre.
- L'export Android (APK) atteint l'étape finale en configuration complète mais échoue en `--headless` sous Windows (bug d'alignement de Godot 4.3) : voir `docs/ANDROID.md`. Le build Android passe par l'éditeur ou la CI.

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
