#!/bin/bash
# Install Pegasus (built aarch64 binary) and the "Game Mode - 模拟器" launcher
# under /opt/pegasus. Everything outside the prefix is recorded in
# /opt/pegasus/INSTALL-MANIFEST.tsv so uninstall.sh can reverse it.
#
# Usage:
#   sudo ./scripts/install.sh [--binary PATH] [--roms DIR] [--no-config]
set -euo pipefail

PREFIX=/opt/pegasus
REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
BINARY="$REPO_DIR/build/src/app/pegasus-fe"
USER_HOME=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)
ROMS="$USER_HOME/文档/pegasus-roms"
WITH_CONFIG=1

while [ $# -gt 0 ]; do
    case "$1" in
        --binary) BINARY="$2"; shift 2 ;;
        --roms) ROMS="$2"; shift 2 ;;
        --no-config) WITH_CONFIG=0; shift ;;
        *) echo "usage: $0 [--binary PATH] [--roms DIR] [--no-config]" >&2; exit 2 ;;
    esac
done

[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }
[ -x "$BINARY" ] || { echo "missing binary: $BINARY (build first, or pass --binary)" >&2; exit 1; }

APPS="$USER_HOME/.local/share/applications"
CONF="$USER_HOME/.config/pegasus-frontend"
MANIFEST="$PREFIX/INSTALL-MANIFEST.tsv"

mkdir -p "$PREFIX/bin" "$PREFIX/share/config"
install -m755 "$BINARY" "$PREFIX/bin/pegasus-fe"
install -m755 "$REPO_DIR/scripts/game-mode-emulators.sh" "$PREFIX/bin/game-mode-emulators.sh"
install -m644 "$REPO_DIR/config/"*.txt "$PREFIX/share/config/"
install -m755 "$REPO_DIR/scripts/uninstall.sh" "$PREFIX/uninstall.sh"

{
    echo "# mtgpu-pegasus install manifest (kind<TAB>path<TAB>note)"
    echo "# 'file'/'symlink' entries are removed by uninstall.sh;"
    echo "# 'apt' entries are informational and left installed on purpose."
} >"$MANIFEST"

record() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$MANIFEST"; }

# --- user-level integration (outside the prefix, recorded) ------------------
mkdir -p "$APPS"
install -m644 "$REPO_DIR/scripts/desktop/game-mode-emulators.desktop" \
    "$APPS/game-mode-emulators.desktop"
record file "$APPS/game-mode-emulators.desktop" "menu entry: Game Mode - 模拟器"

if [ "$WITH_CONFIG" -eq 1 ]; then
    mkdir -p "$CONF"
    if [ ! -f "$CONF/game_dirs.txt" ]; then
        sed "s|{{ROMS}}|$ROMS|g" "$REPO_DIR/config/game_dirs.txt" >"$CONF/game_dirs.txt"
        record file "$CONF/game_dirs.txt" "pegasus game directories"
    fi
    for p in nes snes gb gba doom; do
        mkdir -p "$ROMS/$p"
        if [ ! -f "$ROMS/$p/metadata.pegasus.txt" ]; then
            cp "$REPO_DIR/config/metadata.$p.txt" "$ROMS/$p/metadata.pegasus.txt"
            record file "$ROMS/$p/metadata.pegasus.txt" "pegasus collection metadata"
        fi
    done
fi

# --- dependencies (installed via apt, not owned by this prefix) ------------
for pkg in retroarch libretro-nestopia libretro-snes9x libretro-gambatte \
           libretro-mgba libretro-genesisplusgx chocolate-doom dosbox; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        record apt "$pkg" "dependency (kept on uninstall)"
    else
        echo "warning: $pkg is not installed; see docs/INSTALL.md" >&2
    fi
done

echo "installed to $PREFIX"
echo "menu entry: Game Mode - 模拟器"
echo "uninstall with: sudo $PREFIX/uninstall.sh"
