#!/bin/bash
# Runs at login of the generic user: asks who owns the notebook and hands
# off to asignar-run.sh (root, via a scoped sudoers rule).
set -u

die() {
    zenity --error --no-markup --title="Asignar equipo" --text="$1"
    exit 1
}

command -v zenity >/dev/null || exit 0

. /etc/default/asignar-pc

# Without network the assignment cannot even start: say so instead of
# closing the session for nothing.
until timeout 20 git ls-remote --heads "$ASIGNAR_REPO" >/dev/null 2>&1; do
    zenity --question --title="Asignar equipo" --ok-label="Reintentar" --cancel-label="Más tarde" \
        --text="Para configurar este equipo hace falta internet.\n\nConectate a una red (arriba a la derecha) y tocá Reintentar." || exit 0
done

while true; do
    OUT=$(zenity --forms --title="Asignar equipo" \
        --text="Este equipo todavía no tiene dueño. Completá tus datos para configurarlo." \
        --add-entry="Usuario (ej: jperez)" \
        --add-entry="Nombre y apellido" \
        --separator=$'\t') || exit 0
    NEW=${OUT%%$'\t'*}
    FULL=${OUT#*$'\t'}
    NEW=${NEW,,}
    if [[ ! $NEW =~ ^[a-z][a-z0-9-]{1,31}$ ]]; then
        zenity --error --no-markup --text="El usuario solo puede tener minúsculas, números y guión, y empezar con letra: $NEW"
        continue
    fi
    if [[ ! $FULL =~ ^[[:alpha:][:space:].-]{3,80}$ ]]; then
        zenity --error --text="El nombre solo puede tener letras y espacios."
        continue
    fi
    break
done

zenity --question --title="Asignar equipo" \
    --text="Se va a asignar este equipo a:\n\n<b>$FULL</b>\nUsuario: $NEW\nEquipo: $NEW-adhoc-nb\n\nLa sesión se cierra y el equipo se configura solo. La pantalla de ingreso te avisa cuando termina.\n\n¿Continuar?" || exit 0

ERR=$(sudo -n /usr/local/bin/asignar-run.sh "$USER" "$NEW" "$FULL" 2>&1) ||
    die "No se pudo iniciar la asignación: $ERR"

zenity --info --title="Asignar equipo" --timeout=5 \
    --text="Se cierra tu sesión. Seguí las indicaciones en la pantalla de ingreso."

# Logout limpio: el playbook encuentra la sesión ya cerrada.
gnome-session-quit --logout --no-prompt 2>/dev/null || loginctl terminate-user "$USER"
