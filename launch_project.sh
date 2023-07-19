#!/usr/bin/env bash
# Script para preparar notebooks en Adhoc. Instala dependencias, clona el proyecto de ansible y aplica el rol Funcional.

# Verificar ejecución con sudo
if [[ $EUID -ne 0 ]]; then
  echo "Este script requiere privilegios root. Ejecutar con sudo"
  exit 1
fi

# Función para instalar paquetes (si no están instalados)
function install_package_if_not_installed {
  if ! dpkg -s "$1" &>/dev/null; then
    apt install -y "$1"
  fi
}

# Actualización completa del sistema
printf "[PREPARAR NOTEBOOK] ACTUALIZAR AMBIENTE DE TRABAJO\n"
apt update -y
apt upgrade -y

# Instalar dependencias
printf "[PREPARAR NOTEBOOK] INSTALAR GIT Y STOW\n"
install_package_if_not_installed git
install_package_if_not_installed stow

# Instalar dependencias de ansible
printf "[PREPARAR NOTEBOOK] INSTALAR DEPENDENCIAS\n"
install_package_if_not_installed python3-setuptools

# Instalar ansible
printf "[PREPARAR NOTEBOOK] INSTALAR ANSIBLE\n"
install_package_if_not_installed ansible

printf "[PREPARAR NOTEBOOK] NOTEBOOK LISTA!\n"

# Clonar proyecto y ejecutar rol Funcional
printf "[PROYECTO ANSIBLE] CLONAR REPOSITORIO\n"
PROJECT_DIR="/opt/ansible_notebooks"
LOG_FILE="/var/log/ansible.log"
git clone https://github.com/ingadhoc/ansible_notebooks "$PROJECT_DIR"
chown -R $USER:$USER "$LOG_FILE"

function launch {
  read -e -p "COMENZAR PREPARACIÓN DEL ROL BASE? ( 'si', 'no' ): " LAUNCH_OPTION

  while [[ "$LAUNCH_OPTION" != "si" && "$LAUNCH_OPTION" != "no" ]]; do
    read -e -p "Por favor seleccionar una opción correcta ( 'si', 'no' ): " LAUNCH_OPTION
  done

  if [[ "$LAUNCH_OPTION" == "si" ]]; then
    ansible-playbook --tags "funcional" "$PROJECT_DIR/local.yml" -K --verbose
  else
    read -e -p "Gracias por lanzar el proyecto, ver README.md para más información."
  fi
}

launch
