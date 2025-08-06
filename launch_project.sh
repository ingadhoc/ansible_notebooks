#!/usr/bin/env bash

# Salir inmediatamente si un comando falla.
set -euo pipefail

## --- CONFIGURACIÓN ---
readonly REPO_URL="https://github.com/ingadhoc/ansible_notebooks.git"

# Colores para la salida
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

# 2. Instalar dependencias base
log "Instalando dependencias base (git, pipx)..."
apt-get update -y > /dev/null
apt-get install -y git pipx > /dev/null

# 3. Desinstalar versiones de Ansible del sistema para evitar conflictos
log "Desinstalando cualquier versión de Ansible gestionada por apt..."
apt-get remove --purge -y ansible ansible-core || true
apt-get autoremove -y > /dev/null

# 4. Instalar Ansible de forma segura con pipx
log "Instalando Ansible vía pipx para el usuario '$SCRIPT_USER'..."
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

# 6. Mensaje final con instrucciones
log "${GREEN}¡PREPARACIÓN COMPLETADA!${RESET}"
echo ""
echo -e "El sistema base y Ansible han sido instalados."
echo -e "Para completar la configuración, por favor sigue estos pasos:"
echo ""
echo -e "  1. ${BOLD}Cierra esta terminal y abre una nueva.${RESET}"
echo -e "     (Esto es MUY IMPORTANTE para que se actualice el entorno)."
echo ""
echo -e "  2. ${BOLD}Navega al directorio del proyecto:${RESET}"
echo -e "     ${GREEN}cd ~/repositorios/ansible_notebooks${RESET}"
echo ""
echo -e "  3. ${BOLD}Instala las colecciones de Ansible:${RESET}"
echo -e "     ${GREEN}ansible-galaxy install -r collections/requirements.yml${RESET}"
echo ""
echo -e "  4. ${BOLD}Ejecuta el perfil que desees (ej. Funcional):${RESET}"
echo -e "     ${GREEN}ansible-playbook local.yml -K --verbose${RESET}"
echo ""
