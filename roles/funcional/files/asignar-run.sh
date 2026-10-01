#!/bin/bash
# Root side of the self-service assignment. The sudoers rule lets the generic
# user run this with any arguments, so validation here is the security boundary.
set -euo pipefail

usage() { echo "uso: $0 <old_user> <new_user> <nombre completo>" >&2; exit 2; }
[ $# -eq 3 ] || usage
OLD_USER=$1
NEW_USER=${2,,}
FULL_NAME=$3

. /etc/default/asignar-pc

[[ $OLD_USER =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { echo "usuario viejo inválido" >&2; exit 2; }
id "$OLD_USER" >/dev/null 2>&1 || { echo "el usuario $OLD_USER no existe" >&2; exit 2; }
[ "$OLD_USER" = "${SUDO_USER:-}" ] || { echo "solo podés asignar el usuario con el que entraste" >&2; exit 2; }
[[ $FULL_NAME =~ ^[[:alpha:][:space:].-]{3,80}$ ]] || { echo "nombre inválido" >&2; exit 2; }

# No "_": it is not valid in the hostname built from the user name.
[[ $NEW_USER =~ ^[a-z][a-z0-9-]{1,31}$ ]] || { echo "usuario nuevo inválido: $NEW_USER" >&2; exit 2; }
# Covers users and groups: groupmod -n fails on an existing group name.
{ getent passwd "$NEW_USER" || getent group "$NEW_USER"; } >/dev/null &&
    { echo "el nombre $NEW_USER ya está en uso" >&2; exit 2; }

EXTRA_VARS=$(python3 -c 'import json,sys; print(json.dumps(dict(
    old_user=sys.argv[1], new_user=sys.argv[2], full_name=sys.argv[3],
    hostname=sys.argv[2] + "-adhoc-nb", asignar_banner=sys.argv[4] == "true")))' \
    "$OLD_USER" "$NEW_USER" "$FULL_NAME" "$ASIGNAR_BANNER")

install -d -m 0750 /var/lib/asignar
echo "$OLD_USER $NEW_USER" >/var/lib/asignar/en-curso
touch /var/log/asignar.log
echo "$(date -Is) asignar $OLD_USER -> $NEW_USER ($FULL_NAME) rama=$ASIGNAR_BRANCH" >>/var/log/asignar.log

# Transient system unit: runs as root outside the user session, so it
# survives loginctl terminate-user and the home move done by the playbook.
systemd-run --unit=asignar-pc --collect --setenv=PYTHONUNBUFFERED=1 \
    --description="Asignación de notebook a $NEW_USER" \
    -p StandardOutput=append:/var/log/asignar.log -p StandardError=inherit \
    /usr/local/bin/asignar-unit.sh "$EXTRA_VARS"
