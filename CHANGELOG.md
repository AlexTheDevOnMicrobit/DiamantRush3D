# Changelog

## 3.2.0

### Nouveau
- **3 mondes secrets** (13 à 15), débloqués en terminant l'Aventure : Abysses Lumineuses, Pays des Sucreries, Forteresse de l'Ombre (avec décors, musique de synthèse, particules et chapitre d'histoire). Jouables en Monde libre et inclus dans le Mode infini. 15 mondes au total.
- **5 boss différents** (mondes 3, 6, 9, 12 et 15) : chaque boss a sa couleur, son jeu d'attaques et son rythme ; nouvelle attaque, le **rayon rotatif** ; musique de combat optionnelle (`audio/music/boss`).
- **2 nouveaux types de dalles** (18 au total) : **bumper** (repousse Lumi) et **plaque de glace** (sol glissant partout).
- **Étoiles** (jusqu'à 3 par étape : finir, toutes les pièces, aucune chute), conservées par monde et affichées dans le Monde libre.
- **Chapeaux** (6) et **traînées** de particules (5) pour Lumi, débloqués avec les étoiles, en plus des 8 couleurs (pièces).
- **3 nouveaux modificateurs** : Nuit noire (lampe de Lumi), Sans checkpoint, Lumi miniature.
- **Astuces** : la première fois qu'un type de dalle apparaît, une astuce l'explique (désactivable).
- **Série de défis du jour** : bonus de pièces par jour consécutif, succès « Assidu ».
- **9 nouveaux succès** (29 au total) et nouvelles statistiques (étoiles, bumpers, portails, boss vaincus distincts).
- **4 nouvelles langues** : espagnol, allemand, italien, portugais (Brésil), soit 6 langues avec le français et l'anglais ; langue automatique selon le système.
- **Audio prêt pour tes propres fichiers** : chargeur qui accepte `.ogg`, `.wav`, `.mp3` et les doubles extensions, **suppression du silence de fin** et **égalisation automatique** du volume des effets fournis, musiques de monde / menu / histoire / boss / jingles par fichier, 8 nouveaux sons de synthèse (`bumper`, `star`, `boss_wake`, `boss_shot`, `boss_beam`, `equip`, `streak`, `tip`) et tous les sons existants raccordés (`hit`, `launch`, `cannon`, `portal`…).
- Outil `tools/check_audio.gd` et `audio/README.md` complet (noms, durées, caractère de chaque piste et effet attendus).

### Corrigé / ajusté
- Les fichiers audio à double extension (`jump.ogg.wav`) et l'orthographe `loose` sont reconnus ; les jingles ne bouclent plus.
- Le bumper a une zone d'action plus petite pour laisser des couloirs pour le contourner.

### Vérifié
- `tests/smoke.gd` : 230 vérifications, dont les 15 mondes avec tous les modificateurs, chaque nouveau piège, les 5 variantes de boss, la complétude des 6 langues et les 11 pages de menu dans chaque langue.
- Le robot de test joue les 15 mondes (environ 83 % de parcours réussis ; ses échecs viennent surtout des bumpers, des plaques de glace et des canons, qu'il gère mal : ces pièges restent à valider à la main).

## 3.1.0

### Nouveau
- **Boss de fin de monde** (mondes 3, 6, 9 et 12) : l'Ombre et son arène (balayages de boules, météores signalés, tirs ciblés), 3 vies, le diamant n'apparaît qu'après sa défaite.
- **6 nouveaux types de dalles** (16 au total) : canon, lanceur directionnel, interrupteur + pont, portail d'entrée + sortie.
- **Mode infini** : étapes courtes qui s'enchaînent, difficulté croissante, 3 vies (+1 toutes les 3 étapes), classement local.
- **Défis du jour et de la semaine** : seed et modificateurs imposés, objectif, récompense en pièces.
- **Codes de partage** (`DR1-…`) : mode, seed et modificateurs en une chaîne à copier / coller.
- **Fantôme** du meilleur temps d'une étape (même seed, même monde, mêmes réglages de longueur, difficulté et miroir).
- **Classement local** (top 10 général et top 10 infini), nouvelles statistiques (boss, meilleure série infinie), 4 nouveaux succès (20 au total).
- **Version anglaise** complète (menus, HUD, histoire, succès) avec choix de la langue dans les options.
- **Accessibilité** : mode daltonien (palette Okabe-Ito + symboles), symboles sur les dalles, aide au saut, taille du texte, touches du clavier réassignables.
- **Caméra qui ne traverse plus les dalles** et **disque d'ombre** sous Lumi pour juger les atterrissages.
- **Mises à jour** : vérification (désactivable) de la dernière Release GitHub avec bouton de téléchargement dans le menu.
- **Chargeur audio** : les fichiers déposés dans `audio/music/` et `audio/sfx/` remplacent automatiquement les sons synthétisés ; 8 nouveaux sons synthétisés (bonus, succès, coup, portail, lanceur, canon, jingle de fin de run).
- Outils et documentation : `tools/screenshots.gd`, `docs/STORE_PAGE.md` (textes de boutique FR/EN, politique de confidentialité), `docs/MACOS_SIGNING.md`, `audio/README.md`.

### Corrigé / ajusté
- Les symboles non latins (étoiles, coches) ont été remplacés par du texte simple pour s'afficher aussi sur Web et Android.
- Un lanceur garde son élan en l'air (le contrôle aérien est réduit après le lancement) et sa portée est identique quelle que soit la gravité.
- Le générateur n'interrompt jamais une paire portail/sortie ou interrupteur/pont.
- Le réglage de repli de langue est fixé sur le français pour que le texte source ne soit pas traduit par erreur.
- Le robot de test esquive les tirs, utilise les portails et les interrupteurs, et compte l'arrivée dans l'arène comme une réussite (environ 95 % de parcours réussis, tous mondes confondus ; les échecs restants viennent surtout de ses limites : glace, canons).

### Vérifié
- `tests/smoke.gd` : 172 vérifications (générateur, 12 mondes avec tous les modificateurs, chaque piège, boss, mode infini, défis, codes, fantôme, runs, succès, sauvegarde, touches, mises à jour, traductions, 11 pages de menu en français et en anglais, tactile, manette, accessibilité, caméra).
- Exports Windows, Linux, Web, macOS et Android construits en ligne de commande.

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
- Export Android (APK debug) construit en ligne de commande, signé et vérifié avec `apksigner` (v1, v2, v3). Sous Windows, certains antivirus font échouer les exports : désactiver « Safe Save » dans l'éditeur (voir `docs/ANDROID.md`).
- Le build Web exige le rendu Compatibilité : réglage `renderer/rendering_method.web` rétabli.

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
