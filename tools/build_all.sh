#!/usr/bin/env bash
# Exporte le jeu pour toutes les plateformes demandées (modèles d'export Godot 4.3 requis).
# Usage : GODOT=/chemin/vers/godot tools/build_all.sh [windows linux web macos android aab]
# Android : voir docs/ANDROID.md (JAVA_HOME, SDK, clés de signature).
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
VERSION="$(grep -oP 'config/version="\K[^"]+' project.godot)"
TARGETS=("$@")
[ ${#TARGETS[@]} -eq 0 ] && TARGETS=(windows linux web macos)

"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
mkdir -p build dist
fail=0

export_one() { # nom_preset fichier_sortie
  local preset="$1" out="$2"
  mkdir -p "$(dirname "$out")"
  echo "==> $preset"
  "$GODOT" --headless --path . --export-release "$preset" "$out" 2>&1 | tail -3
  if [ -s "$out" ]; then
    echo "    OK : $out"
  else
    echo "    ECHEC : $preset"
    fail=1
  fi
}

for t in "${TARGETS[@]}"; do
  case "$t" in
    windows) export_one "Windows Desktop" build/windows/DiamantRush3D.exe ;;
    linux)   export_one "Linux" build/linux/DiamantRush3D.x86_64 ;;
    web)     export_one "Web" build/web/index.html ;;
    macos)   export_one "macOS" build/macos/DiamantRush3D.zip ;;
    android) export_one "Android" build/android/DiamantRush3D.apk ;;
    aab)     export_one "Android AAB (Google Play)" build/android/DiamantRush3D.aab ;;
    *) echo "Cible inconnue : $t"; fail=1 ;;
  esac
done

# archives de distribution
[ -f build/windows/DiamantRush3D.exe ] && (cd build/windows && zip -qj "../../dist/DiamantRush3D-$VERSION-windows.zip" DiamantRush3D.exe)
[ -f build/linux/DiamantRush3D.x86_64 ] && (cd build/linux && zip -qj "../../dist/DiamantRush3D-$VERSION-linux.zip" DiamantRush3D.x86_64)
[ -f build/web/index.html ] && (cd build/web && zip -qr "../../dist/DiamantRush3D-$VERSION-web.zip" .)
[ -f build/macos/DiamantRush3D.zip ] && cp build/macos/DiamantRush3D.zip "dist/DiamantRush3D-$VERSION-macos.zip"
[ -f build/android/DiamantRush3D.apk ] && cp build/android/DiamantRush3D.apk "dist/DiamantRush3D-$VERSION-android.apk"
[ -f build/android/DiamantRush3D.aab ] && cp build/android/DiamantRush3D.aab "dist/DiamantRush3D-$VERSION-android.aab"
echo "Archives dans dist/ :"
ls -1 dist 2>/dev/null
exit $fail
