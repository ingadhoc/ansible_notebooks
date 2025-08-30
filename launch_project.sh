#!/usr/bin/env bash

# Salir inmediatamente si un comando falla.
set -euo pipefail

## --- CONFIGURACIÓN ---
readonly REPO_URL="https://github.com/ingadhoc/ansible_notebooks.git"

# Colores para la salida
readonly C_RED="\033[1;31m"
readonly C_GREEN="\033[1;32m"
readonly C_BLUE="\033[1;34m"
readonly C_RESET="\033[0m"
readonly C_BOLD="\033[1m"

## --- FUNCIONES ---
log() {
  echo -e "${C_BLUE}${C_BOLD}[BOOTSTRAP]${C_RESET} $1"
}

error() {
  echo -e "${C_RED}${C_BOLD}[ERROR]${C_RESET} $1" >&2
  exit 1
}

## --- EJECUCIÓN ---

# 1. Verificar privilegios y obtener el usuario original
if [[ $EUID -ne 0 ]]; then
  error "Este script requiere privilegios de superusuario. Por favor, ejecútalo con 'sudo'."
fi
readonly SCRIPT_USER="${SUDO_USER:-$(logname)}"
readonly USER_HOME="/home/$SCRIPT_USER"
readonly REPO_DIR="$USER_HOME/repositorios/ansible_notebooks"
readonly PIPX_BIN_DIR="$USER_HOME/.local/bin"

# 2. Instalar dependencias base
log "Instalando dependencias base (git, pipx)..."
apt-get update -y > /dev/null
apt-get install -y git pipx > /dev/null

# 3. Asegurar una instalación limpia de Ansible del sistema
log "Desinstalando cualquier versión de Ansible gestionada por apt..."
apt-get remove --purge -y ansible ansible-core > /dev/null || true
apt-get autovemove -y > /dev/null

# 4. Instalar Ansible de forma segura con pipx
log "Instalando Ansible vía pipx para el usuario '$SCRIPT_USER'..."
# ⭐️ CORRECCIÓN CLAVE: Usar 'runuser -l' en lugar de 'sudo -u'
# Esto asegura que el entorno del usuario ($HOME, etc.) se cargue correctamente.
runuser -l "$SCRIPT_USER" -c "pipx install ansible-core --force"
runuser -l "$SCRIPT_USER" -c "pipx ensurepath"

# Hacemos que los comandos de pipx estén disponibles en ESTA sesión para no tener que reiniciar
export PATH="$PIPX_BIN_DIR:$PATH"
log "PATH actualizado temporalmente para esta sesión."

# 5. Clonar/actualizar el repositorio del proyecto
log "Clonando/actualizando el repositorio de Ansible en $REPO_DIR..."
mkdir -p "$(dirname "$REPO_DIR")"
chown -R "$SCRIPT_USER:$SCRIPT_USER" "$(dirname "$REPO_DIR")"

if [ -d "$REPO_DIR/.git" ]; then
    runuser -l "$SCRIPT_USER" -c "git -C '$REPO_DIR' pull"
else
    runuser -l "$SCRIPT_USER" -c "git clone '$REPO_URL' '$REPO_DIR'"
fi

# 6. Instalar colecciones de Ansible (Paso automatizado)
log "Instalando colecciones de Ansible..."
runuser -l "$SCRIPT_USER" -c "cd '$REPO_DIR' && ansible-galaxy install -r collections/requirements.yml"

# 7. Menú interactivo
log "Por favor, selecciona el perfil para provisionar esta notebook:"
# (El resto del script con el menú y la ejecución de ansible puede quedar como en la versión mejorada anterior)
# ...
PS3="Ingresa el número de tu opción: "
options=("Funcional" "Devs" "SysAdmin" "Salir y ejecutar manualmente")
select opt in "${options[@]}"; do
  case $opt in
    "Funcional") PROFILE_TO_RUN="funcional"; break;;
    "Devs") PROFILE_TO_RUN="devs"; break;;
    "SysAdmin") PROFILE_TO_RUN="sysadmin"; break;;
    "Salir y ejecutar manualmente")
      log "Instalación base completada. Puedes ejecutar playbooks manualmente."
      exit 0
      ;;
    *) echo "Opción inválida $REPLY" ;;
  esac
done

# 8. Ejecutar Ansible
log "Ejecutando Ansible con el perfil '${PROFILE_TO_RUN}'..."
COMMAND_TO_RUN="cd '$REPO_DIR' && ansible-playbook local.yml -e 'profile_override=${PROFILE_TO_RUN}' -K"
runuser -l "$SCRIPT_USER" -c "$COMMAND_TO_RUN"

# 9. Mensaje final
log "${C_GREEN}¡PROCESO COMPLETADO!${C_RESET}"
echo -e "${C_RED}${C_BOLD}# IMPORTANTE:${C_RESET} Por favor, REINICIA la notebook para que se apliquen todos los cambios."
