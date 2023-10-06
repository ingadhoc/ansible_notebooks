#!/usr/bin/env bash
## Script para preparar notebooks en Adhoc. Instala dependencias,
## clona el proyecto de ansible y aplica el rol Funcional.

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
printf "[PREPARAR NOTEBOOK] INSTALAR GIT Y STOW\n"
install_package_if_not_installed git
install_package_if_not_installed stow

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
cd $REPO_DIR

# Mostrar las instrucciones para el usuario
echo "Deployar roles EN ESTE ORDEN ya que cada uno es dependencia del siguiente:"
echo "Rol funcional para Operaciones, Comercial, RRHH"
echo "$ ansible-playbook --tags \"funcional\" local.yml -K --verbose"
echo "Rol dev para I+D"
echo "$ ansible-playbook --tags \"devs\" local.yml -K --verbose"
echo "#IMPORTANTE: Reiniciar la notebook luego de aplicar el rol dev para que apliquen los cambios y configuraciones (docker as root por ejemplo)"
echo "Rol sysadmin para Infraestructura & DevOps"
echo "$ ansible-playbook --tags \"sysadmin\" local.yml -K --verbose"

# Nota adicional para el usuario
echo "Gracias por lanzar el proyecto, ver README.md para más información."
