#!/usr/bin/env bash
# Script para preparar notebooks. Instala dependencias, clona el repositorio del proyecto y luego aplica el rol base "Funcional".

# Actualizar sistema
echo "[PREPARAR NOTEBOOK] ACTUALIZAR AMBIENTE DE TRABAJO"
sudo apt-get -y update
sudo apt-get -y upgrade

# Instalar requerimientos
echo "[PREPARAR NOTEBOOK] INSTALAR GIT Y STOW"
sudo apt-get install -y git stow

# Instalar dependencias de Ansible
echo '[PREPARAR NOTEBOOK] INSTALAR DEPENDENCIAS'
sudo apt-get install -y python3-setuptools

# Instalar Ansible
echo "[PREPARAR NOTEBOOK] INSTALAR ANSIBLE"
sudo apt-get install -y ansible

echo '[PREPARAR NOTEBOOK] NOTEBOOK LISTA!'

# Deploy projecto Ansible, implementación
echo "[PROYECTO ANSIBLE] CLONAR REPOSITORIO"
sudo touch /var/log/ansible.log
sudo chown -R $USER:$USER /var/log/ansible.log
git clone https://github.com/adhoc-dev/ansible.git
cd ansible

# Para ejecutar el rol base
function launch {
    read -e -p "COMENZAR PREPARACIÓN DEL ROL BASE? ( 'si', 'no' ): " LAUNCH_OPTION

    while [[ "$LAUNCH_OPTION" != "si" && "$LAUNCH_OPTION" != "no" ]]; do
        read -e -p "Por favor seleccionar una opción correcta ( 'si', 'no' ): " LAUNCH_OPTION
    done

    if [[ "$LAUNCH_OPTION" == "si" ]]; then
        ansible-playbook --tags "funcional" local.yml -K --verbose
    fi

    if [[ "$LAUNCH_OPTION" == "no" ]]; then
        read -e -p "Gracias por lanzar el proyecto, ver README.md para más información."
    fi

}

launch
