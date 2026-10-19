# Signer et notariser la version macOS

Sans signature, macOS bloque l'application (« développeur non identifié ») : l'utilisateur doit faire clic droit → Ouvrir.
Pour une diffusion large, il faut signer et notariser. **Cela demande un compte Apple Developer payant (99 $/an)**
et un Mac pour la partie signature : je ne peux pas le faire à ta place.

## 1. Prérequis (une seule fois)

1. Compte [Apple Developer Program](https://developer.apple.com/programs/).
2. Sur un Mac avec Xcode : crée un certificat **Developer ID Application** (Xcode → Settings → Accounts → Manage Certificates).
3. Crée un mot de passe d'application sur <https://appleid.apple.com> (pour la notarisation).
4. Note ton **Team ID** (developer.apple.com → Membership).

## 2. Exporter signé depuis Godot

1. Éditeur → Projet → Exporter → preset **macOS**.
2. Section *Codesign* : `Codesign` = *Xcode codesign*, `Identity` = « Developer ID Application: Ton Nom (TEAMID) ».
3. Section *Notarization* : `Notarization` = *Xcode notarytool*, puis Apple ID, mot de passe d'application et Team ID.
4. Garde `Hardened Runtime` activé et coche les entitlements utiles (`Disable Library Validation` n'est pas nécessaire ici).
5. Exporte : Godot signe, soumet à Apple et agrafe le ticket.

## 3. Sans Mac : CI GitHub (macOS runner)

Un runner `macos-latest` peut signer. Ajoute ces secrets au dépôt (Settings → Secrets) : le certificat `.p12` en base64
(`MACOS_CERT_P12`, `MACOS_CERT_PASSWORD`), `APPLE_ID`, `APPLE_APP_PASSWORD`, `APPLE_TEAM_ID`. Le workflow doit importer le
certificat dans un trousseau temporaire puis lancer `godot --headless --export-release "macOS"` avec les options de
signature passées via les paramètres du preset. Voir la documentation Godot « Exporting for macOS ».

## 4. Vérifier

```bash
codesign --verify --deep --strict --verbose=2 DiamantRush3D.app
spctl --assess --type execute --verbose DiamantRush3D.app
xcrun stapler validate DiamantRush3D.app
```

## 5. Publication des mises à jour

Le jeu vérifie au démarrage (option activable dans Options) s'il existe une Release GitHub plus récente que `Global.VERSION`
et affiche un bouton « Nouvelle version disponible » dans le menu principal. Pour publier :

1. Mets à jour `config/version` (`project.godot`), `Global.VERSION` (`scripts/global.gd`), les versions des presets d'export et le CHANGELOG.
2. Pousse un tag `vX.Y.Z` : la CI construit tout et crée la Release avec les archives.
3. Les joueurs voient l'annonce au prochain lancement.
