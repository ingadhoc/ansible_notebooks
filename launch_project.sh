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

# 2. Instalar dependencias iniciales y configurar repositorios de Ansible
log "Instalando dependencias para gestión de repositorios..."
apt-get update -y > /dev/null
apt-get install -y curl gpg lsb-release ca-certificates > /dev/null

# Detectar la distribución para añadir el repositorio oficial de Ansible
OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
OS_CODENAME=$(lsb_release -cs)

if [[ "$OS_ID" == "ubuntu" ]]; then
  log "Configurando el PPA oficial de Ansible para Ubuntu..."
  apt-get install -y software-properties-common > /dev/null
  add-apt-repository --yes --update ppa:ansible/ansible
elif [[ "$OS_ID" == "debian" ]]; then
  log "Configurando el repositorio oficial de Ansible para Debian..."
  curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367 | gpg --dearmor -o /usr/share/keyrings/ansible-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu ${OS_CODENAME} main" | tee /etc/apt/sources.list.d/ansible.list > /dev/null
  apt-get update -y > /dev/null
fi

# 3. Instalar Ansible y Git
log "Instalando una versión moderna de Ansible y Git..."
apt-get install -y git ansible > /dev/null

# 4. Clonar el repositorio del proyecto
log "Clonando el repositorio de Ansible en $REPO_DIR..."
mkdir -p "$(dirname "$REPO_DIR")"
chown -R "$SCRIPT_USER:$SCRIPT_USER" "$(dirname "$REPO_DIR")"
# Clonamos o actualizamos el repo como el usuario final
if [ -d "$REPO_DIR/.git" ]; then
    sudo -u "$SCRIPT_USER" git -C "$REPO_DIR" pull
else
    sudo -u "$SCRIPT_USER" git clone "$REPO_URL" "$REPO_DIR"
fi

# 5. Instalar colecciones de Ansible desde el archivo de requerimientos
log "Instalando colecciones de Ansible desde 'collections/requirements.yml'..."
sudo -u "$SCRIPT_USER" ansible-galaxy install -r "$REPO_DIR/collections/requirements.yml"

# 6. Menú interactivo (sin cambios)
log "Por favor, selecciona el perfil para provisionar esta notebook:"
PS3="Ingresa el número de tu opción: "
options=("Funcional" "Devs" "SysAdmin" "Salir")
select opt in "${options[@]}"; do
  # ... (el resto del menú y la ejecución de ansible-playbook sigue igual)
  case $opt in
    "Funcional") PROFILE_TO_RUN="funcional"; break;;
    "Devs") PROFILE_TO_RUN="devs"; break;;
    "SysAdmin") PROFILE_TO_RUN="sysadmin"; break;;
    "Salir")
      log "Instalación automática cancelada."
      echo -e "Puedes ejecutar el playbook manualmente. Consulta el ${GREEN}README.md${RESET}."
      exit 0
      ;;
    *) echo "Opción inválida $REPLY" ;;
  esac
done

# 7. Ejecutar Ansible (sin cambios)
log "Ejecutando Ansible con el perfil '${PROFILE_TO_RUN}'. Se te pedirá la contraseña de sudo..."
COMMAND_TO_RUN="ansible-playbook local.yml -e 'profile_override=${PROFILE_TO_RUN}' -K"
sudo -u "$SCRIPT_USER" bash -c "cd '$REPO_DIR' && $COMMAND_TO_RUN"

# 8. Mensaje final (sin cambios)
log "${GREEN}¡PROCESO COMPLETADO!${RESET}"
echo -e "${RED}${BOLD}# IMPORTANTE:${RESET} Por favor, REINICIA la notebook para que se apliquen todos los cambios."
