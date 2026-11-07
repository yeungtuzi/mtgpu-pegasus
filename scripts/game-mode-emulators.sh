#!/bin/bash
# "Game Mode - 模拟器": switch the KDE output to 1280x720@59.97 (scale 1),
# start Pegasus fullscreen, and restore the previous mode/scale on exit.
# Stays on the current VT (no chvt) and never replaces the desktop session.
set -u

PREFIX=${PEGASUS_PREFIX:-/opt/pegasus}
KSD=${KSCREEN_DOCTOR:-/opt/kde6/bin/kscreen-doctor}
STATE=${XDG_CONFIG_HOME:-$HOME/.config}/mtgpu-pegasus-gamemode.state
LOG=${XDG_CONFIG_HOME:-$HOME/.config}/mtgpu-pegasus-gamemode.log
TARGET_MODE=${PEGASUS_GAMEMODE_MODE:-1280x720}

log() { echo "$(date -Is) $*" >>"$LOG"; }

env_session() {
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
    export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
    export DISPLAY="${DISPLAY:-:0}"
    if [ -z "${XAUTHORITY:-}" ]; then
        XAUTHORITY=$(ls "/run/user/$(id -u)"/xauth_* 2>/dev/null | head -1)
        export XAUTHORITY
    fi
}

ks() { env_session; "$KSD" "$@" >/dev/null 2>&1; }

output_name() {
    env_session
    "$KSD" -o 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' |
        grep -m1 -oE 'Output: [0-9]+ [^ ]+' | awk '{print $3}'
}

current_mode_index() {
    env_session
    "$KSD" -o 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' |
        tr ' ' '\n' | grep -oE '^[0-9]+:[^ ]*\*' | head -1 | cut -d: -f1
}

current_scale() {
    env_session
    "$KSD" -o 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' |
        grep -m1 'Scale:' | grep -oE '[0-9.]+' | head -1
}

mode_index_for() {
    env_session
    "$KSD" -o 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' |
        tr ' ' '\n' | grep -oE "^[0-9]+:${1}@" | head -1 | cut -d: -f1
}

restore() {
    local reason="${1:-manual}"
    [ -f "$STATE" ] || { log "not in game mode"; return 0; }
    # shellcheck disable=SC1090
    . "$STATE"
    ks "output.${OUT:-eDP-1}.mode.${MODE:-1}" "output.${OUT:-eDP-1}.scale.${SCALE:-2}"
    rm -f "$STATE"
    log "restored mode=${MODE:-1} scale=${SCALE:-2} ($reason)"
}

start() {
    if [ -f "$STATE" ]; then log "already active"; return 0; fi
    local out mode720 cur_mode cur_scale
    out=$(output_name); out=${out:-eDP-1}
    cur_mode=$(current_mode_index); cur_scale=$(current_scale)
    [ -n "$cur_mode" ] || { log "cannot read current mode"; return 1; }
    mode720=$(mode_index_for "$TARGET_MODE")
    [ -n "$mode720" ] || { log "no $TARGET_MODE mode on $out"; return 1; }
    # If the desktop is already in the 720p mode, remember the native mode
    # instead so exiting really restores the full-resolution desktop.
    if [ "$cur_mode" = "$mode720" ]; then
        cur_mode=$(mode_index_for "2880x1800")
        cur_mode=${cur_mode:-1}
        cur_scale=2
        log "already at $TARGET_MODE; will restore native mode $cur_mode scale $cur_scale"
    fi

    printf 'OUT=%s\nMODE=%s\nSCALE=%s\nMODE720=%s\n' \
        "$out" "$cur_mode" "${cur_scale:-2}" "$mode720" >"$STATE"
    ks "output.$out.mode.$mode720" "output.$out.scale.1.0"
    log "switched $out to mode $mode720 ($TARGET_MODE) scale 1.0; was mode=$cur_mode scale=${cur_scale:-2}"

    env_session
    # M1000's EGL cannot create a dri2 screen under KDE Wayland; QML would
    # render black. The software Quick backend is fine for a 2D UI.
    export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
    export QT_QUICK_BACKEND="${QT_QUICK_BACKEND:-software}"
    "$PREFIX/bin/pegasus-fe" >>"$LOG" 2>&1
    restore "pegasus exited"
}

stop() { restore "${1:-manual}"; }

status() {
    if [ -f "$STATE" ]; then echo "game-mode: active ($(tr '\n' ' ' <"$STATE"))";
    else echo "game-mode: inactive"; fi
}

case "${1:-status}" in
    start) start ;;
    stop) shift || true; stop "${1:-manual}" ;;
    status) status ;;
    *) echo "usage: $0 {start|stop|status}"; exit 2 ;;
esac
