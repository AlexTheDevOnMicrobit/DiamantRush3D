# Construire l'APK / AAB Android

Le jeu est prêt pour Android : preset d'export `Android` (APK) et `Android AAB (Google Play)`, commandes tactiles,
orientation paysage, rendu *Compatibilité* (OpenGL ES 3), vibrations, bouton « retour » géré, marges de sécurité (encoche).

## 1. Prérequis (une seule fois)

| Élément | Version | Où |
|---|---|---|
| Godot | 4.3 (standard) + **modèles d'export** | Éditeur → *Gérer les modèles d'exportation* |
| JDK | 17 (21 fonctionne souvent aussi) | Adoptium / OpenJDK |
| Android SDK | `platform-tools`, `build-tools;34.0.0`, `platforms;android-34`, `cmdline-tools;latest` | Android Studio → SDK Manager, ou `sdkmanager` |

Dans Godot : **Éditeur → Paramètres de l'éditeur → Export → Android** :

- *Java SDK Path* : le dossier du JDK
- *Android SDK Path* : le dossier du SDK (souvent `%LOCALAPPDATA%\Android\Sdk`)
- *Debug Keystore* : voir ci-dessous

## 2. Clés de signature

APK de test (debug) : crée un keystore debug

```bash
tools/make_keystore.sh debug
```

puis indique son chemin (identifiant `androiddebugkey`, mot de passe `android`) dans les paramètres de l'éditeur ou avec les variables d'environnement :

```bash
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH=/chemin/debug.keystore
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android
```

Publication (release / Google Play) : crée **ta** clé et **garde-la précieusement** (fichier + mot de passe), sans elle tu ne pourras plus mettre à jour le jeu :

```bash
tools/make_keystore.sh release
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/chemin/release.keystore
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=<alias>
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=<mot de passe>
```

Le dossier `tools/keys/` et les fichiers `*.keystore` / `*.jks` sont ignorés par git : ne les commite jamais.

## 3. Exporter

### Depuis l'éditeur (recommandé sous Windows)

**Projet → Exporter… → Android → Exporter le projet** (ou *Déployer en un clic* avec un téléphone en mode développeur relié en USB).

### En ligne de commande

```bash
godot --headless --path . --export-debug   "Android" build/android/DiamantRush3D.apk   # test
godot --headless --path . --export-release "Android" build/android/DiamantRush3D.apk   # nécessite une clé release
```

> **Windows : « Safe save failed » / « Impossible de décompresser l'APK temporaire »**. Certains antivirus verrouillent les
> fichiers temporaires de Godot et font échouer les exports (Android, mais aussi parfois Windows / Linux / Web). Solution :
> dans l'éditeur, **Paramètres de l'éditeur → Système de fichiers → Sur enregistrement → désactive « Safe Save On Backup Then Rename »**
> (clé `filesystem/on_save/safe_save_on_backup_then_rename`), ou ajoute le dossier de Godot aux exclusions de l'antivirus.
> Un message « Cannot remove file … tmpexport-unaligned … » en fin d'export est sans gravité si l'APK est bien produit
> (vérification : `apksigner verify --verbose DiamantRush3D.apk`).

### AAB pour Google Play

1. **Projet → Installer le modèle de build Android** (une fois ; crée le dossier `android/` ignoré par git).
2. Exporte avec le preset **Android AAB (Google Play)** : `build/android/DiamantRush3D.aab`.
3. Dans la Play Console, crée l'application avec l'identifiant `com.diamantrush.game` (à changer dans le preset si tu veux le tien, avant le premier envoi : il est définitif).

## 4. Réglages du jeu pour mobile

- Qualité graphique par défaut : **Basse** sur mobile (Options → Qualité).
- Commandes tactiles : *Automatique* (affichées sur Android / iOS / navigateur mobile), modifiables dans Options ; la taille est réglable.
- Vibrations : activables dans Options.
- Le bouton « retour » d'Android ouvre la pause en jeu et revient au menu principal dans les menus.

## 5. iOS (non fourni)

L'export iOS demande un Mac, Xcode et un compte développeur Apple. Ajoute un preset *iOS* dans l'éditeur (identifiant
`com.diamantrush.game`, équipe Apple, icônes) ; le reste du jeu est compatible (même code que sur Android).
