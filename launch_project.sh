#!/usr/bin/env bash
## Script para preparar notebooks en Adhoc. Instala dependencias,
## clona el proyecto de ansible y ofrece instrucciones.

# Colores ANSI
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
RESET="\033[0m"
BOLD="\033[1m"
NORMAL="\033[0m"
YELLOW_BG="\033[43m"

# Guardar el nombre de usuario que está ejecutando el script
SCRIPT_USER=$SUDO_USER

# Verificar ejecución con sudo
if [[ $EUID -ne 0 ]]; then
  echo "Este script requiere privilegios root. Ejecutar con sudo"
  exit 1
fi

# Función para instalar paquetes (si no están instalados)
function install_package_if_not_installed {
  dpkg -s "$1" &>/dev/null || apt install -y "$1"
}

# Actualización completa del sistema
printf "[PREPARAR NOTEBOOK] ACTUALIZAR AMBIENTE DE TRABAJO\n"
apt update -y && apt upgrade -y

# Instalar herramientas
printf "[PREPARAR NOTEBOOK] INSTALAR GIT\n"
install_package_if_not_installed git

# Instalar dependencias de ansible
printf "[PREPARAR NOTEBOOK] INSTALAR DEPENDENCIAS DE ANSIBLE\n"
install_package_if_not_installed python3-setuptools

# Instalar ansible
printf "[PREPARAR NOTEBOOK] INSTALAR ANSIBLE\n"
install_package_if_not_installed ansible

printf "[PREPARAR NOTEBOOK] NOTEBOOK LISTA!\n"

# Crear el archivo ansible.log en /var/log con los permisos adecuados
ANSIBLE_LOG_FILE="/var/log/ansible.log"
touch "$ANSIBLE_LOG_FILE"
chown "$SCRIPT_USER:$SCRIPT_USER" "$ANSIBLE_LOG_FILE"

# Clonar proyecto y ejecutar rol Funcional
REPO_DIR="/home/$SCRIPT_USER/repositorios/ansible_notebooks"

printf "[PROYECTO ANSIBLE] CLONAR REPOSITORIO\n"
if [ ! -d "$REPO_DIR" ]; then
  mkdir -p "$REPO_DIR"
fi
chown -R "$SCRIPT_USER:$SCRIPT_USER" "/home/$SCRIPT_USER/repositorios/"
sudo -u "$SCRIPT_USER" git clone https://github.com/ingadhoc/ansible_notebooks.git "$REPO_DIR"

# Mostrar las instrucciones para el usuario
echo -e "${BLUE}#IMPORTANTE:${RESET} Reiniciar luego de aplicar cada rol para que se apliquen los cambios y configuraciones (gnome extensions, docker as root por ejemplo)."
echo -e "${RED}Deployar EN ESTE ORDEN${RESET} ya que cada uno es dependencia del siguiente:"
echo -e "${BOLD}${YELLOW_BG}$ cd ~/repositorios/ansible_notebooks${NORMAL}"
echo -e "==========================================================="

echo -e "${GREEN}Rol funcional para Operaciones, Comercial, RRHH:${RESET}"
echo -e "${BOLD}${YELLOW_BG}$ ansible-playbook --tags \"funcional\" local.yml -K --verbose${NORMAL}"
echo -e "==========================================================="

echo -e "${GREEN}Rol dev para I+D:${RESET}"
echo -e "${BOLD}${YELLOW_BG}$ ansible-playbook --tags \"devs\" local.yml -K --verbose${NORMAL}"

echo -e "==========================================================="
echo -e "${GREEN}Rol sysadmin para Infraestructura & DevOps:${RESET}"
echo -e "${BOLD}${YELLOW_BG}$ ansible-playbook --tags \"sysadmin\" local.yml -K --verbose${NORMAL}"

# Nota adicional para el usuario
echo -e "${MAGENTA}Gracias por lanzar el proyecto, ver README.md para más información.${RESET}"
