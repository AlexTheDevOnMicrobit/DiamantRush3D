#!/usr/bin/env bash
# Crée un keystore Android (debug ou release) dans tools/keys/ (ignoré par git).
# Usage : tools/make_keystore.sh debug|release        (keytool doit être dans le PATH : il vient avec le JDK)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p tools/keys
kind="${1:-debug}"
if [ "$kind" = "debug" ]; then
  keytool -genkeypair -keystore tools/keys/debug.keystore -storepass android -alias androiddebugkey -keypass android \
    -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
  echo "Debug : export GODOT_ANDROID_KEYSTORE_DEBUG_PATH=$PWD/tools/keys/debug.keystore GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android"
else
  read -r -p "Alias : " alias_name
  read -r -s -p "Mot de passe (keystore et clé) : " pass
  echo
  keytool -genkeypair -keystore tools/keys/release.keystore -storepass "$pass" -alias "$alias_name" -keypass "$pass" \
    -keyalg RSA -keysize 2048 -validity 10000
  echo "Release : export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$PWD/tools/keys/release.keystore GODOT_ANDROID_KEYSTORE_RELEASE_USER=$alias_name GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=<mot de passe>"
  echo "SAUVEGARDE ce fichier et le mot de passe : sans eux, impossible de publier des mises à jour."
fi
