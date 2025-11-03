#!/usr/bin/env bash
# Quick start script para comenzar con los tests
# Este script prepara el entorno de desarrollo para testing

set -euo pipefail

readonly C_GREEN="\033[1;32m"
readonly C_BLUE="\033[1;34m"
readonly C_YELLOW="\033[1;33m"
readonly C_RESET="\033[0m"

log() {
  echo -e "${C_BLUE}[SETUP]${C_RESET} $1"
}

success() {
  echo -e "${C_GREEN}[OK]${C_RESET} $1"
}

warn() {
  echo -e "${C_YELLOW}[INFO]${C_RESET} $1"
}

log "Configurando entorno de testing para ansible_notebooks..."
echo

# 1. Verificar Python
log "Verificando Python 3..."
if command -v python3 &> /dev/null; then
  python_version=$(python3 --version)
  success "Python encontrado: $python_version"
else
  echo "ERROR: Python 3 no encontrado. Por favor instalalo primero."
  exit 1
fi

# 2. Verificar Docker
log "Verificando Docker..."
if command -v docker &> /dev/null; then
  docker_version=$(docker --version)
  success "Docker encontrado: $docker_version"
  
  if docker ps &> /dev/null; then
    success "Docker daemon esta corriendo"
  else
    warn "Docker daemon no responde. Intenta: sudo systemctl start docker"
  fi
else
  echo "ERROR: Docker no encontrado. Por favor instalalo primero."
  exit 1
fi

# 3. Crear virtualenv si no existe
log "Configurando entorno virtual Python..."
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
  success "Virtualenv creado en .venv/"
else
  warn "Virtualenv ya existe en .venv/"
fi

# 4. Activar virtualenv e instalar dependencias
log "Instalando dependencias de testing..."
source .venv/bin/activate

pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements-dev.txt

success "Dependencias instaladas"

# 5. Instalar colecciones de Ansible
log "Instalando colecciones de Ansible..."
ansible-galaxy install -r collections/requirements.yml

success "Colecciones instaladas"

# 6. Hacer ejecutables los scripts
chmod +x test-role.sh

echo
success "Entorno de testing configurado exitosamente"
echo
echo "Proximos pasos:"
echo "  1. Activa el virtualenv: source .venv/bin/activate"
echo "  2. Ejecuta tests: ./test-role.sh funcional"
echo "  3. Lee la documentacion: cat TESTING.md"
echo
warn "Recuerda: Para usar estos comandos en el futuro, activa el venv primero:"
echo "  -> source .venv/bin/activate"
