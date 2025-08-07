#!/usr/bin/env bash

# Salir inmediatamente si un comando falla.
set -euo pipefail

## --- CONFIGURACIÓN ---
readonly REPO_URL="https://github.com/ingadhoc/ansible_notebooks.git"
readonly ANSIBLE_LOG_FILE="/var/log/ansible.log"

# Colores para la salida
readonly RED="\033[1;31m"
readonly GREEN="\033[1;32m"
readonly BLUE="\033[1;34m"
readonly RESET="\033[0m"
readonly BOLD="\033[1m"

## --- FUNCIONES ---
log() {
  echo -e "${BLUE}${BOLD}[BOOTSTRAP]${RESET} $1"
}

## --- EJECUCIÓN ---

# 1. Verificar privilegios y obtener el usuario original
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Este script requiere privilegios de superusuario. Por favor, ejecútalo con 'sudo'.${RESET}"
  exit 1
fi
readonly SCRIPT_USER="${SUDO_USER:-$(logname)}"
readonly REPO_DIR="/home/$SCRIPT_USER/repositorios/ansible_notebooks"

# 2. Instalar dependencias base, incluyendo pipx
log "Instalando dependencias base (git, pipx)..."
apt-get update -y > /dev/null
apt-get install -y git pipx > /dev/null

# 3. Asegurar una instalación limpia de Ansible del sistema
log "Desinstalando cualquier versión de Ansible gestionada por apt..."
apt-get remove --purge -y ansible ansible-core || true
apt-get autoremove -y > /dev/null

# 4. Instalar Ansible de forma segura con pipx
log "Instalando Ansible vía pipx para el usuario '$SCRIPT_USER'..."
# Usamos --force para reparar instalaciones corruptas o incompletas
sudo -u "$SCRIPT_USER" pipx install ansible-core --force
sudo -u "$SCRIPT_USER" pipx ensurepath

# 5. Clonar el repositorio del proyecto
log "Clonando/actualizando el repositorio de Ansible en $REPO_DIR..."
mkdir -p "$(dirname "$REPO_DIR")"
chown -R "$SCRIPT_USER:$SCRIPT_USER" "$(dirname "$REPO_DIR")"
if [ -d "$REPO_DIR/.git" ]; then
    sudo -u "$SCRIPT_USER" git -C "$REPO_DIR" pull
else
    sudo -u "$SCRIPT_USER" git clone "$REPO_URL" "$REPO_DIR"
fi

# ✅ NUEVO PASO: Crear el archivo de instrucciones antes del menú
readonly INSTRUCTIONS_FILE="/home/$SCRIPT_USER/INSTRUCCIONES_ANSIBLE.txt"
log "Creando un archivo de ayuda en ${INSTRUCTIONS_FILE}..."
# Usamos un 'heredoc' para escribir un bloque de texto multilínea.
cat << EOF > "$INSTRUCTIONS_FILE"
#####################################################################
#               Instrucciones para Ejecutar Ansible
#####################################################################

El sistema base y Ansible han sido instalados. Para completar la
configuración, por favor sigue estos pasos en una nueva terminal.

1. Navega al directorio del proyecto:
   cd ~/repositorios/ansible_notebooks

2. Instala las colecciones de Ansible:
   ansible-galaxy install -r collections/requirements.yml

3. Ejecuta el perfil que desees. Ejemplos:

   # Para el rol Funcional (perfil por defecto)
   ansible-playbook local.yml -K --verbose

   # Para el rol Devs (ejecutará funcional y luego devs)
   ansible-playbook local.yml -e "profile_override=devs" -K --verbose

   # Para el rol SysAdmin (ejecutará funcional, devs y luego sysadmin)
   ansible-playbook local.yml -e "profile_override=sysadmin" -K --verbose

#####################################################################
EOF
# Asignamos el archivo al usuario correcto
chown "$SCRIPT_USER:$SCRIPT_USER" "$INSTRUCTIONS_FILE"


# 6. Menú interactivo
log "Por favor, selecciona el perfil para provisionar esta notebook:"
PS3="Ingresa el número de tu opción: "
options=("Funcional" "Devs" "SysAdmin" "Salir y ejecutar manualmente")
select opt in "${options[@]}"; do
  case $opt in
    "Funcional") PROFILE_TO_RUN="funcional"; break;;
    "Devs") PROFILE_TO_RUN="devs"; break;;
    "SysAdmin") PROFILE_TO_RUN="sysadmin"; break;;
    "Salir y ejecutar manualmente")
      log "Instalación automática cancelada."
      echo -e "Puedes seguir las instrucciones guardadas en el archivo ${GREEN}${INSTRUCTIONS_FILE}${RESET}"
      exit 0
      ;;
    *) echo "Opción inválida $REPLY" ;;
  esac
done

# 7. Ejecutar Ansible
log "Ejecutando Ansible con el perfil '${PROFILE_TO_RUN}'..."
ANSIBLE_CMD="/home/$SCRIPT_USER/.local/bin/ansible-playbook"
COMMAND_TO_RUN="$ANSIBLE_CMD local.yml -e 'profile_override=${PROFILE_TO_RUN}' -K"
sudo -u "$SCRIPT_USER" bash -c "cd '$REPO_DIR' && $COMMAND_TO_RUN"


# 8. Mensaje final
log "${GREEN}¡PROCESO COMPLETADO!${RESET}"
echo -e "${RED}${BOLD}# IMPORTANTE:${RESET} Por favor, REINICIA la notebook para que se apliquen todos los cambios."
echo -e "Si necesitas volver a ejecutar un playbook, las instrucciones están en ${GREEN}${INSTRUCTIONS_FILE}${RESET}"
