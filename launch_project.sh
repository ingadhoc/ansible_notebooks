#!/usr/bin/env bash
set -euo pipefail

## --- CONFIGURACIÓN ---
readonly REPO_URL="https://github.com/ingadhoc/ansible_notebooks.git"
readonly C_RED="\033[1;31m"
readonly C_GREEN="\033[1;32m"
readonly C_BLUE="\033[1;34m"
readonly C_YELLOW="\033[1;33m"
readonly C_RESET="\033[0m"
readonly C_BOLD="\033[1m"

## --- FUNCIONES ---
log() {
  echo -e "${C_BLUE}${C_BOLD}[BOOTSTRAP]${C_RESET} $1"
}

warn() {
  echo -e "${C_YELLOW}${C_BOLD}[WARN]${C_RESET} $1"
}

error() {
  echo -e "${C_RED}${C_BOLD}[ERROR]${C_RESET} $1" >&2
  exit 1
}

success() {
  echo -e "${C_GREEN}${C_BOLD}[OK]${C_RESET} $1"
}

# Detectar distribución
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  else
    error "No se pudo detectar la distribución del sistema"
  fi
}

## --- EJECUCIÓN ---
log "Iniciando bootstrap de Ansible para notebooks Adhoc..."

# 1. Verificar privilegios
if [[ $EUID -ne 0 ]]; then
  error "Este script requiere privilegios de superusuario. Ejecútalo con: sudo bash $0"
fi

readonly SCRIPT_USER="${SUDO_USER:-$(logname)}"
readonly USER_HOME=$(eval echo ~"$SCRIPT_USER")
readonly REPO_DIR="$USER_HOME/repositorios/ansible_notebooks"
readonly PIPX_BIN_DIR="$USER_HOME/.local/bin"
readonly PIPX_VENVS_DIR="$USER_HOME/.local/pipx/venvs"

log "Usuario detectado: $SCRIPT_USER"
log "Directorio home: $USER_HOME"

# 2. Detectar distribución
readonly DISTRO=$(detect_distro)
log "Distribución detectada: $DISTRO"

# 3. Instalar dependencias base
log "Actualizando repositorios de paquetes..."
apt-get update -y > /dev/null 2>&1

log "Instalando dependencias base (git, python3, pip)..."
apt-get install -y git python3 python3-pip python3-venv ca-certificates curl > /dev/null 2>&1
success "Dependencias base instaladas"

# 4. Desinstalar Ansible del sistema si existe
log "Desinstalando cualquier versión de Ansible gestionada por apt..."
apt-get remove --purge -y ansible ansible-core > /dev/null 2>&1 || true
apt-get autoremove -y > /dev/null 2>&1
success "Sistema limpio de instalaciones previas de Ansible"

# 5. Instalar pipx
log "Instalando pipx..."

# Asegurar que el directorio .local/bin existe
mkdir -p "$PIPX_BIN_DIR"
chown "$SCRIPT_USER:$SCRIPT_USER" "$PIPX_BIN_DIR"

# Instalar pipx vía apt (esto instala el módulo Python)
if apt-cache show pipx > /dev/null 2>&1; then
    log "Instalando pipx vía apt..."
    apt-get install -y pipx > /dev/null 2>&1
fi

# Verificar que pipx funciona como módulo
log "Verificando instalación de pipx..."
if ! runuser -u "$SCRIPT_USER" -- python3 -m pipx --version > /dev/null 2>&1; then
    error "pipx no está funcionando correctamente. Verifica la instalación de Python."
fi

success "pipx instalado y funcionando (python3 -m pipx)"

# 6. Configurar ensurepath de pipx
log "Configurando PATH de pipx..."
runuser -u "$SCRIPT_USER" -- python3 -m pipx ensurepath > /dev/null 2>&1 || true
success "PATH de pipx configurado"

# 7. Limpiar instalación previa de Ansible si existe
log "Limpiando cualquier instalación previa de Ansible vía pipx..."
runuser -u "$SCRIPT_USER" -- python3 -m pipx uninstall ansible-core > /dev/null 2>&1 || true
runuser -u "$SCRIPT_USER" -- python3 -m pipx uninstall ansible > /dev/null 2>&1 || true

# Eliminar manualmente el venv si aún existe (por si quedó corrupto)
if [ -d "$PIPX_VENVS_DIR/ansible-core" ]; then
    log "Eliminando venv corrupto de ansible-core..."
    rm -rf "$PIPX_VENVS_DIR/ansible-core"
fi

success "Limpieza completa realizada"

# 8. Instalar Ansible con pipx (instalación limpia)
log "Instalando Ansible Core vía pipx (instalación limpia)..."
runuser -u "$SCRIPT_USER" -- python3 -m pipx install ansible-core

# Dar tiempo para que se complete la instalación
sleep 2

# Verificar instalación de Ansible
ANSIBLE_PLAYBOOK_PATH="$PIPX_BIN_DIR/ansible-playbook"
ANSIBLE_PATH="$PIPX_BIN_DIR/ansible"
ANSIBLE_GALAXY_PATH="$PIPX_BIN_DIR/ansible-galaxy"

log "Verificando binarios instalados en $PIPX_BIN_DIR..."
log "Contenido del directorio:"
ls -lah "$PIPX_BIN_DIR" | grep ansible || true

if [ ! -f "$ANSIBLE_PLAYBOOK_PATH" ]; then
    error "ansible-playbook no se instaló correctamente en $PIPX_BIN_DIR
    
    Contenido completo de $PIPX_BIN_DIR:
    $(ls -la $PIPX_BIN_DIR 2>/dev/null || echo 'El directorio no existe o está vacío')
    
    Estado de pipx:
    $(runuser -u $SCRIPT_USER -- python3 -m pipx list)
    
    Intenta ejecutar manualmente:
    sudo -u $SCRIPT_USER python3 -m pipx uninstall ansible-core
    sudo -u $SCRIPT_USER python3 -m pipx install ansible-core
    sudo -u $SCRIPT_USER ls -la $PIPX_BIN_DIR"
fi

success "Ansible instalado exitosamente en $PIPX_BIN_DIR"

# Verificar versión
if [ -f "$ANSIBLE_PATH" ]; then
    VERSION=$(runuser -u "$SCRIPT_USER" -- "$ANSIBLE_PATH" --version 2>/dev/null | head -n1 || echo "No se pudo obtener versión")
    log "Versión: $VERSION"
else
    warn "No se pudo verificar la versión de Ansible"
fi

# 9. Clonar/actualizar repositorio
log "Gestionando repositorio de playbooks en $REPO_DIR..."

mkdir -p "$(dirname "$REPO_DIR")"
chown -R "$SCRIPT_USER:$SCRIPT_USER" "$(dirname "$REPO_DIR")"

if [ -d "$REPO_DIR/.git" ]; then
    log "Repositorio existe, actualizando..."
    runuser -u "$SCRIPT_USER" -- git -C "$REPO_DIR" pull
else
    log "Clonando repositorio..."
    runuser -u "$SCRIPT_USER" -- git clone "$REPO_URL" "$REPO_DIR"
fi
success "Repositorio listo en $REPO_DIR"

# 10. Instalar colecciones de Ansible
if [ -f "$REPO_DIR/collections/requirements.yml" ]; then
    log "Instalando colecciones de Ansible..."
    
    if [ ! -f "$ANSIBLE_GALAXY_PATH" ]; then
        error "ansible-galaxy no existe en $ANSIBLE_GALAXY_PATH. No se pueden instalar colecciones."
    fi
    
    runuser -u "$SCRIPT_USER" -- "$ANSIBLE_GALAXY_PATH" install -r "$REPO_DIR/collections/requirements.yml"
    success "Colecciones de Ansible instaladas"
else
    warn "No se encontró collections/requirements.yml, omitiendo instalación de colecciones"
fi

# 11. Menú interactivo
echo ""
log "┌─────────────────────────────────────────────┐"
log "│  Selecciona el perfil para esta notebook:  │"
log "└─────────────────────────────────────────────┘"
echo ""

PS3="Ingresa el número de tu opción: "
options=("Funcional" "Developer" "SysAdmin" "Salir (ejecutar manualmente después)")

select opt in "${options[@]}"; do
  case $opt in
    "Funcional")
      PROFILE_TO_RUN="funcional"
      break
      ;;
    "Developer")
      PROFILE_TO_RUN="developer"
      break
      ;;
    "SysAdmin")
      PROFILE_TO_RUN="sysadmin"
      break
      ;;
    "Salir (ejecutar manualmente después)")
      echo ""
      success "Instalación base completada exitosamente"
      echo ""
      log "Para ejecutar manualmente, usa:"
      echo -e "  ${C_BOLD}cd $REPO_DIR${C_RESET}"
      echo -e "  ${C_BOLD}ansible-playbook local.yml -e 'profile_override=PERFIL' -K${C_RESET}"
      echo ""
      log "Perfiles disponibles: funcional, developer, sysadmin"
      exit 0
      ;;
    *)
      echo "Opción inválida '$REPLY'. Por favor, selecciona un número válido."
      ;;
  esac
done

# 12. Ejecutar Ansible playbook
echo ""
log "Ejecutando Ansible Playbook con perfil: ${C_BOLD}${PROFILE_TO_RUN}${C_RESET}"
echo ""

PLAYBOOK_FILE="$REPO_DIR/local.yml"

# Verificar que el playbook existe
if [ ! -f "$PLAYBOOK_FILE" ]; then
    error "No se encontró el playbook en $PLAYBOOK_FILE"
fi

# Ejecutar como el usuario original
runuser -u "$SCRIPT_USER" -- bash -c "cd '$REPO_DIR' && '$ANSIBLE_PLAYBOOK_PATH' local.yml -e 'profile_override=${PROFILE_TO_RUN}' -K"

# 13. Mensaje final
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "¡PROCESO COMPLETADO EXITOSAMENTE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${C_RED}${C_BOLD}⚠️  ACCIÓN REQUERIDA:${C_RESET}"
echo -e "   Por favor, ${C_BOLD}REINICIA${C_RESET} tu notebook para que todos los cambios surtan efecto."
echo ""
log "Perfil aplicado: ${C_BOLD}${PROFILE_TO_RUN}${C_RESET}"
log "Repositorio: $REPO_DIR"
log "Binarios de Ansible: $PIPX_BIN_DIR"
echo ""
