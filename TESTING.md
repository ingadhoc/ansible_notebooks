# Ansible Testing Guide - ansible_notebooks

Este documento explica cómo ejecutar los tests localmente y entender el flujo de CI/CD.

## Requisitos

- Docker instalado y en ejecución
- Python 3.11+
- Permisos para ejecutar contenedores Docker

## Setup Inicial

1. **Instalar dependencias de desarrollo:**

```bash
pip install -r requirements-dev.txt
```

2. **Instalar colecciones de Ansible:**

```bash
ansible-galaxy install -r collections/requirements.yml
```

## Ejecutar Tests Localmente

### Tests del rol funcional

```bash
cd roles/funcional
molecule test
```

### Comandos de Molecule útiles

```bash
# Crear el contenedor sin ejecutar playbook
molecule create

# Ejecutar el playbook (converge)
molecule converge

# Ejecutar las verificaciones
molecule verify

# Ver el estado de los contenedores
molecule list

# Conectarse al contenedor para debugging
molecule login

# Destruir los contenedores
molecule destroy

# Test completo (create -> converge -> verify -> destroy)
molecule test
```

### Test de Idempotencia

Molecule ejecuta el playbook dos veces para verificar idempotencia. En la segunda ejecución no debería haber cambios:

```bash
molecule test --scenario-name default
```

### Tests por Distribución

Para testear solo una distribución específica:

```bash
# Solo Debian 12
MOLECULE_DISTRO=debian12 molecule test

# Solo Ubuntu 22.04
MOLECULE_DISTRO=ubuntu2204 molecule test
```

## Estructura de Tests

```
roles/funcional/molecule/default/
├── molecule.yml       # Configuración de Molecule
├── converge.yml       # Playbook que ejecuta el rol
├── verify.yml         # Tests de verificación
└── prepare.yml        # Preparación del entorno de test
```

## CI/CD con GitHub Actions

El workflow `.github/workflows/molecule.yml` ejecuta:

1. **Lint**: Validación de sintaxis YAML y Ansible
2. **Test funcional**: Tests del rol base (matriz: Debian 12 + Ubuntu 22.04)
3. **Test developer**: Tests del rol developer (pendiente de implementar)
4. **Test sysadmin**: Tests del rol sysadmin (pendiente de implementar)

### Triggers del CI

- Push a branches `main` o `develop`
- Pull Requests a `main` o `develop`
- Manual via `workflow_dispatch`

## Debugging Tests Fallidos

### Localmente

```bash
# Mantener el contenedor después de fallos
molecule converge
molecule login
# Investigar dentro del contenedor
```

### En GitHub Actions

Los logs se suben como artifacts cuando fallan los tests. Puedes descargarlos desde la página de Actions.

## Próximos Pasos

1. Implementar tests para rol `developer`
2. Implementar tests para rol `sysadmin`
3. Agregar tests de configuraciones específicas (GNOME, SSH, Git)
4. Validar herencia de roles en tests

## Troubleshooting

### Error: "Cannot connect to Docker daemon"

```bash
sudo systemctl start docker
sudo usermod -aG docker $USER
# Logout y login nuevamente
```

### Error: "Port already in use"

```bash
molecule destroy
docker ps -a | grep molecule
docker rm -f <container-id>
```

### Tests lentos

```bash
# Usar caché de paquetes
export MOLECULE_NO_LOG=false
molecule test --destroy=never
```
