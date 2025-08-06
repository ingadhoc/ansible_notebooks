#!/usr/bin/env bash

# Salir inmediatamente si un comando falla.
set -euo pipefail

## --- CONFIGURACIÓN ---
# Define las variables en un solo lugar para facilitar el mantenimiento.
readonly REPO_URL="https://github.com/ingadhoc/ansible_notebooks.git"
readonly ANSIBLE_LOG_FILE="/var/log/ansible.log"

# Colores para la salida
readonly RED="\033[1;31m"
readonly GREEN="\033[1;32m"
readonly YELLOW="\033[1;33m"
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
# Si el script se ejecuta como root directamente (no sudo), SCRIPT_USER estaría vacío.
readonly SCRIPT_USER="${SUDO_USER:-$(logname)}"
readonly REPO_DIR="/home/$SCRIPT_USER/repositorios/ansible_notebooks"

# 2. Actualizar sistema e instalar dependencias
log "Actualizando el sistema (esto puede tardar unos minutos)..."
apt-get update -y > /dev/null
# apt-get upgrade -y # Comentado por si se quiere una ejecución más rápida

log "Instalando dependencias base: git, python3 y ansible..."
# Instalamos todo en una sola línea. 'apt' no reinstalará si ya existen.
apt-get install -y git ansible python3-setuptools > /dev/null

# 3. Preparar entorno para Ansible
log "Creando archivo de log en $ANSIBLE_LOG_FILE..."
touch "$ANSIBLE_LOG_FILE"
chown "$SCRIPT_USER:$SCRIPT_USER" "$ANSIBLE_LOG_FILE"

log "Clonando el repositorio de Ansible en $REPO_DIR..."
# Creamos el directorio y asignamos permisos como el usuario final
mkdir -p "$(dirname "$REPO_DIR")"
chown -R "$SCRIPT_USER:$SCRIPT_USER" "$(dirname "$REPO_DIR")"
# Clonamos el repo como el usuario final para evitar problemas de permisos
sudo -u "$SCRIPT_USER" git clone "$REPO_URL" "$REPO_DIR" || true # || true para no fallar si ya existe

# 4. Menú interactivo para seleccionar el perfil 🤖
log "Por favor, selecciona el perfil para provisionar esta notebook:"
PS3="Ingresa el número de tu opción: "
options=("Funcional" "Devs" "SysAdmin" "Salir")
select opt in "${options[@]}"; do
  case $opt in
    "Funcional")
      PROFILE_TO_RUN="funcional"
      break
      ;;
    "Devs")
      PROFILE_TO_RUN="devs"
      break
      ;;
    "SysAdmin")
      PROFILE_TO_RUN="sysadmin"
      break
      ;;
    "Salir")
      log "Instalación cancelada. Puedes ejecutar Ansible manualmente más tarde."
      exit 0
      ;;
    *) echo "Opción inválida $REPLY" ;;
  esac
done

# 5. Ejecutar Ansible
log "Ejecutando Ansible con el perfil '${PROFILE_TO_RUN}'. Se te pedirá la contraseña de sudo..."
COMMAND_TO_RUN="ansible-playbook local.yml -e 'profile_override=${PROFILE_TO_RUN}' -K"

# Ejecutamos el playbook como el usuario original, dentro del directorio correcto.
# El 'bash -c' es para asegurar que el 'cd' y el 'ansible-playbook' se ejecuten en la misma subshell.
sudo -u "$SCRIPT_USER" bash -c "cd '$REPO_DIR' && $COMMAND_TO_RUN"

# 6. Mensaje final
log "${GREEN}¡PROCESO COMPLETADO!${RESET}"
echo -e "${RED}${BOLD}# IMPORTANTE:${RESET} Por favor, REINICIA la notebook para que se apliquen todos los cambios."
