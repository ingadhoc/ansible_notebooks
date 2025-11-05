#!/bin/bash
# Script de setup rapido para entorno de desarrollo
# Uso: curl -sSL https://raw.githubusercontent.com/ingadhoc/ansible_notebooks/main/setup-dev.sh | bash

set -e

echo "Ansible Notebooks - Setup de Desarrollo"
echo "======================================="

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar requisitos
echo -e "${YELLOW}Verificando requisitos...${NC}"

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}ERROR: Python 3 no encontrado. Instalalo primero.${NC}"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo -e "${RED}ERROR: Git no encontrado. Instalalo primero.${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Advertencia: Docker no encontrado. Tests de Molecule no estaran disponibles.${NC}"
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo -e "${GREEN}Python $PYTHON_VERSION encontrado${NC}"

# Crear virtualenv
echo -e "\n${YELLOW}Creando virtualenv...${NC}"
python3 -m venv .venv
source .venv/bin/activate

# Instalar dependencias
echo -e "\n${YELLOW}Instalando dependencias de Python...${NC}"
pip install --upgrade pip setuptools wheel
pip install -r requirements-dev.txt

# Instalar colecciones de Ansible
echo -e "\n${YELLOW}Instalando colecciones de Ansible...${NC}"
ansible-galaxy install -r collections/requirements.yml

# Instalar pre-commit hooks
if [ -f .pre-commit-config.yaml ]; then
    echo -e "\n${YELLOW}Instalando pre-commit hooks...${NC}"
    pip install pre-commit
    pre-commit install
    echo -e "${GREEN}Pre-commit hooks instalados${NC}"
fi

# Verificar instalacion
echo -e "\n${YELLOW}Verificando instalacion...${NC}"
ansible --version | head -n 1
molecule --version

# Informacion util
echo -e "\n${GREEN}======================================="
echo "Setup completado exitosamente"
echo "=======================================${NC}"
echo ""
echo "Proximos pasos:"
echo ""
echo "1. Activar el virtualenv:"
echo "   ${YELLOW}source .venv/bin/activate${NC}"
echo ""
echo "2. Ver comandos disponibles:"
echo "   ${YELLOW}make help${NC}"
echo ""
echo "3. Ejecutar tests:"
echo "   ${YELLOW}make test-funcional${NC}"
echo ""
echo "4. Desarrollo iterativo:"
echo "   ${YELLOW}make dev-create      # Crear contenedores una vez${NC}"
echo "   ${YELLOW}make dev-converge    # Probar cambios${NC}"
echo "   ${YELLOW}make dev-verify      # Verificar${NC}"
echo "   ${YELLOW}make dev-destroy     # Limpiar${NC}"
echo ""
echo "5. Ejecutar playbook localmente:"
echo "   ${YELLOW}make run-dev         # Perfil developer${NC}"
echo "   ${YELLOW}make run-sysadmin    # Perfil sysadmin${NC}"
echo ""
echo "Documentacion:"
echo "   - README.md"
echo "   - docs/"
echo "   - roles/funcional/README.md"
echo ""
echo "GitHub: https://github.com/ingadhoc/ansible_notebooks"
echo ""
