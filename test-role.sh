#!/usr/bin/env bash
# Script helper para ejecutar tests de Molecule
# Uso: ./test-role.sh [funcional|developer|sysadmin|all]

set -euo pipefail

readonly C_RED="\033[1;31m"
readonly C_GREEN="\033[1;32m"
readonly C_BLUE="\033[1;34m"
readonly C_YELLOW="\033[1;33m"
readonly C_RESET="\033[0m"

log() {
  echo -e "${C_BLUE}[TEST]${C_RESET} $1"
}

success() {
  echo -e "${C_GREEN}[OK]${C_RESET} $1"
}

error() {
  echo -e "${C_RED}[ERROR]${C_RESET} $1" >&2
  exit 1
}

warn() {
  echo -e "${C_YELLOW}[WARN]${C_RESET} $1"
}

check_requirements() {
  log "Verificando requisitos..."
  
  if ! command -v docker &> /dev/null; then
    error "Docker no esta instalado o no esta en el PATH"
  fi
  
  if ! docker ps &> /dev/null; then
    error "No se puede conectar al daemon de Docker. Esta corriendo?"
  fi
  
  if ! command -v molecule &> /dev/null; then
    error "Molecule no esta instalado. Ejecuta: pip install -r requirements-dev.txt"
  fi
  
  success "Todos los requisitos cumplidos"
}

test_role() {
  local role=$1
  local role_path="roles/${role}"
  
  if [ ! -d "$role_path" ]; then
    error "El rol '${role}' no existe en ${role_path}"
  fi
  
  if [ ! -d "${role_path}/molecule" ]; then
    warn "El rol '${role}' no tiene tests de Molecule configurados todavia"
    return 0
  fi
  
  log "Ejecutando tests para el rol: ${role}"
  cd "$role_path"
  
  if molecule test; then
    success "Tests del rol '${role}' pasaron exitosamente"
  else
    error "Tests del rol '${role}' fallaron"
  fi
  
  cd - > /dev/null
}

show_usage() {
  cat << EOF
Uso: $0 [OPCIONES] [ROL]

Ejecuta tests de Molecule para los roles de Ansible.

ROLES disponibles:
  funcional     - Rol base
  developer     - Rol de desarrolladores
  sysadmin      - Rol de sysadmins
  all           - Todos los roles (por defecto)

OPCIONES:
  -h, --help    - Muestra esta ayuda
  -c, --check   - Solo verifica requisitos
  -l, --lint    - Solo ejecuta linting

EJEMPLOS:
  $0 funcional              # Test solo rol funcional
  $0 all                    # Test todos los roles
  $0 --check                # Solo verifica requisitos
  $0 --lint                 # Solo ejecuta linting

EOF
}

run_lint() {
  log "Ejecutando linting..."
  
  log "-> Verificando sintaxis YAML..."
  if command -v yamllint &> /dev/null; then
    yamllint .
    success "YAML lint OK"
  else
    warn "yamllint no instalado, saltando..."
  fi
  
  log "-> Verificando sintaxis Ansible..."
  ansible-playbook local.yml --syntax-check
  success "Ansible syntax check OK"
  
  log "-> Ejecutando ansible-lint..."
  if command -v ansible-lint &> /dev/null; then
  ansible-lint local.yml || warn "ansible-lint encontro warnings"
  else
    warn "ansible-lint no instalado, saltando..."
  fi
  
  success "Linting completado"
}

# Parse argumentos
ROLE="${1:-all}"

case "$ROLE" in
  -h|--help)
    show_usage
    exit 0
    ;;
  -c|--check)
    check_requirements
    exit 0
    ;;
  -l|--lint)
    check_requirements
    run_lint
    exit 0
    ;;
  funcional|developer|sysadmin)
    check_requirements
    test_role "$ROLE"
    ;;
  all)
    check_requirements
    log "Ejecutando tests para todos los roles..."
    test_role "funcional"
    test_role "developer"
    test_role "sysadmin"
    success "Todos los tests completados"
    ;;
  *)
    error "Rol desconocido: $ROLE. Usa --help para ver opciones."
    ;;
esac
