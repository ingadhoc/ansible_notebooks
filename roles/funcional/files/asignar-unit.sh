#!/bin/bash
# Runs the assignment inside the transient unit, and the recovery path:
# on failure, or at boot (--recuperar) if the notebook was powered off
# midway. The account must never stay locked behind the banner.
set -u
. /etc/default/asignar-pc
MARCA=/var/lib/asignar/en-curso
GREETER=/etc/gdm3/greeter.dconf-defaults
read -r OLD_USER NEW_USER <"$MARCA"

if [ "$1" != --recuperar ]; then
    timeout 30m /usr/bin/ansible-pull -U "$ASIGNAR_REPO" -C "$ASIGNAR_BRANCH" \
        -d /var/lib/asignar/ansible_notebooks -i hosts asignar.yml -e "$1" &&
        { rm -f "$MARCA"; exit 0; }
fi

# The rename may or may not have happened: unlock whichever user exists.
USUARIO=$OLD_USER
if id "$NEW_USER" >/dev/null 2>&1; then
    USUARIO=$NEW_USER
    rm -f "/home/$NEW_USER/.config/autostart/asignar.desktop" /etc/sudoers.d/asignar
fi
usermod -U "$USUARIO"
rm -f "$MARCA"
[ -f "$GREETER" ] || exit 1
sed -i '/^# BEGIN ASIGNANDO PC$/,/^# END ASIGNANDO PC$/d' "$GREETER"
cat >>"$GREETER" <<BLOCK
# BEGIN ASIGNANDO PC
[org/gnome/login-screen]
disable-user-list=true
banner-message-enable=true
banner-message-text='No se pudo terminar la configuración. Avisá a DevOps. Podés ingresar con el usuario $USUARIO.'
# END ASIGNANDO PC
BLOCK
systemctl restart gdm3
# File left clean: the notice lasts until the next boot, like "Listo".
sed -i '/^# BEGIN ASIGNANDO PC$/,/^# END ASIGNANDO PC$/d' "$GREETER"
# A recovery at boot did its job; a failed assignment is still a failure.
[ "$1" = --recuperar ]
