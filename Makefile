.PHONY: help setup test test-funcional test-developer test-sysadmin lint clean install-hooks

# Variables
VENV := .venv
PYTHON := $(VENV)/bin/python
ANSIBLE := $(VENV)/bin/ansible-playbook
MOLECULE := $(VENV)/bin/molecule

help: ## Mostrar esta ayuda
	@echo "Comandos disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Configurar entorno de desarrollo completo
	@echo "🔧 Configurando entorno de desarrollo..."
	python3 -m venv $(VENV)
	$(VENV)/bin/pip install --upgrade pip
	$(VENV)/bin/pip install -r requirements-dev.txt
	$(VENV)/bin/ansible-galaxy install -r collections/requirements.yml
	@echo "✅ Entorno configurado"

install-hooks: setup ## Instalar pre-commit hooks
	@echo "🪝 Instalando pre-commit hooks..."
	$(VENV)/bin/pre-commit install
	@echo "✅ Hooks instalados"

lint: ## Ejecutar linters (yamllint + ansible-lint)
	@echo "🔍 Ejecutando linters..."
	$(VENV)/bin/yamllint .
	$(VENV)/bin/ansible-lint

test: ## Ejecutar todos los tests (funcional, developer, sysadmin)
	@echo "🧪 Ejecutando todos los tests..."
	./test-role.sh funcional
	./test-role.sh developer
	./test-role.sh sysadmin

test-funcional: ## Test solo del rol funcional
	@echo "🧪 Testing rol funcional..."
	./test-role.sh funcional

test-developer: ## Test solo del rol developer
	@echo "🧪 Testing rol developer..."
	./test-role.sh developer

test-sysadmin: ## Test solo del rol sysadmin
	@echo "🧪 Testing rol sysadmin..."
	./test-role.sh sysadmin

# Comandos de desarrollo iterativo
dev-create: ## Crear contenedores de test (una vez)
	cd roles/funcional && $(MOLECULE) create && $(MOLECULE) prepare

dev-converge: ## Ejecutar converge (iterativo)
	cd roles/funcional && $(MOLECULE) converge

dev-verify: ## Ejecutar verificación
	cd roles/funcional && $(MOLECULE) verify

dev-destroy: ## Destruir contenedores
	cd roles/funcional && $(MOLECULE) destroy

dev-test-tags: ## Ejecutar test con tags específicos (uso: make dev-test-tags TAGS=chrome,gcloud)
	cd roles/funcional && $(MOLECULE) converge -- --tags $(TAGS)

# Testing con múltiples distribuciones
test-debian13: ## Test solo con Debian 13 (requiere imagen Docker disponible)
	@echo "🧪 Testing con Debian 13..."
	cd roles/funcional && $(MOLECULE) converge --platform-name debian13-funcional
	cd roles/funcional && $(MOLECULE) verify --platform-name debian13-funcional

test-ubuntu2404: ## Test solo con Ubuntu 24.04
	@echo "🧪 Testing con Ubuntu 24.04..."
	cd roles/funcional && $(MOLECULE) converge --platform-name ubuntu2404-funcional
	cd roles/funcional && $(MOLECULE) verify --platform-name ubuntu2404-funcional

test-all-distros: ## Test completo con todas las distros (Debian 12/13 + Ubuntu 22.04/24.04)
	@echo "🧪 Testing con todas las distribuciones..."
	@echo "⚠️  Asegúrate de tener las 4 plataformas en molecule.yml"
	cd roles/funcional && $(MOLECULE) test

list-platforms: ## Listar todas las plataformas configuradas en Molecule
	cd roles/funcional && $(MOLECULE) list

docker-pull-images: ## Descargar todas las imágenes Docker necesarias
	@echo "📦 Descargando imágenes Docker..."
	docker pull geerlingguy/docker-debian12-ansible:latest
	docker pull geerlingguy/docker-ubuntu2204-ansible:latest
	@echo "📦 Descargando imágenes adicionales (pueden no existir aún)..."
	docker pull geerlingguy/docker-debian13-ansible:latest || echo "⚠️  Debian 13 image no disponible aún"
	docker pull geerlingguy/docker-ubuntu2404-ansible:latest || echo "✅ Ubuntu 24.04 disponible"

# Ejecución del playbook principal
run: ## Ejecutar playbook local (perfil funcional)
	$(ANSIBLE) local.yml -K --verbose

run-dev: ## Ejecutar playbook local (perfil developer)
	$(ANSIBLE) local.yml -e "profile_override=developer" -K --verbose

run-sysadmin: ## Ejecutar playbook local (perfil sysadmin)
	$(ANSIBLE) local.yml -e "profile_override=sysadmin" -K --verbose

run-deploy: ## Ejecutar solo herramientas de deploy
	$(ANSIBLE) local.yml --tags "deploy" -K --verbose

run-check: ## Ejecutar playbook en modo check (dry-run)
	$(ANSIBLE) local.yml -e "profile_override=developer" -K --check

# Limpieza
clean: ## Limpiar archivos temporales y cache
	@echo "🧹 Limpiando..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .molecule
	rm -f test-output*.log
	@echo "✅ Limpieza completada"

clean-all: clean ## Limpieza completa incluyendo venv
	rm -rf $(VENV)
	@echo "✅ Limpieza completa"

# Información del entorno
info: ## Mostrar información del entorno
	@echo "📊 Información del entorno:"
	@echo "  Python:  $$($(PYTHON) --version 2>&1)"
	@echo "  Ansible: $$($(ANSIBLE) --version | head -n1)"
	@echo "  Molecule: $$($(MOLECULE) --version 2>&1 | head -n1)"
	@echo "  Distribution: $$(lsb_release -ds 2>/dev/null || echo 'Unknown')"

# Actualización de dependencias
update-deps: ## Actualizar dependencias de Ansible
	@echo "⬆️  Actualizando dependencias..."
	$(VENV)/bin/ansible-galaxy install -r collections/requirements.yml --force
	$(VENV)/bin/pip install --upgrade -r requirements-dev.txt
	@echo "✅ Dependencias actualizadas"

# Git helpers
commit: lint ## Hacer commit con pre-commit checks
	@echo "📝 Ejecutando pre-commit checks..."
	$(VENV)/bin/pre-commit run --all-files
	@echo "✅ Listo para commit"

# Documentación
docs: ## Generar/actualizar documentación
	@echo "📚 Documentación ubicada en:"
	@echo "  - README.md"
	@echo "  - docs/"
	@echo "  - roles/*/README.md"

# CI simulation
ci: lint test ## Simular pipeline de CI localmente
	@echo "✅ CI simulation completada"
