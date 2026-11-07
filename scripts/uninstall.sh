#!/bin/bash
# Remove mtgpu-pegasus. Files are taken from /opt/pegasus/INSTALL-MANIFEST.tsv;
# apt packages are intentionally left installed.
set -euo pipefail
PREFIX=/opt/pegasus
MANIFEST="$PREFIX/INSTALL-MANIFEST.tsv"

[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }

if [ -f "$MANIFEST" ]; then
    while IFS=$'\t' read -r kind path _note; do
        case "$kind" in
            file|symlink)
                case "$path" in
                    "$PREFIX"/*|"") continue ;;
                esac
                if [ -e "$path" ] || [ -L "$path" ]; then
                    rm -f "$path" && echo "removed $path"
                fi
                ;;
            apt)
                echo "kept apt package: $path"
                ;;
        esac
    done <"$MANIFEST"
fi

rm -rf "$PREFIX"
echo "removed $PREFIX"
echo "note: ROMs and ~/.config/pegasus-frontend are user data and were not touched."
