# Testing Guide - Ansible Notebooks

Este documento describe el sistema de testing automatizado con Molecule para el proyecto ansible_notebooks.

## Índice

- [Resumen](#resumen)
- [Requisitos](#requisitos)
- [Estructura de Tests](#estructura-de-tests)
- [Ejecución de Tests](#ejecución-de-tests)
- [Workflow Iterativo](#workflow-iterativo)
- [Resolución de Problemas](#resolución-de-problemas)
- [CI/CD](#cicd)

---

## Resumen

El proyecto utiliza **Molecule** con **Docker** para testing automatizado de roles Ansible. Los tests se ejecutan en contenedores Debian 12 y Ubuntu 22.04, validando:

- ✅ Sintaxis de playbooks
- ✅ Instalación correcta de paquetes
- ✅ Idempotencia (segunda ejecución sin cambios)
- ✅ Funcionalidad de binarios instalados

**Estado actual:**
- `funcional`: ✅ Tests completos
- `developer`: ✅ Tests completos (123-126 tasks)
- `sysadmin`: ✅ Tests completos (109 tasks)

---

## Requisitos

### Python Environment

```bash
# Crear entorno virtual
python3 -m venv .venv

# Activar entorno
source .venv/bin/activate

# Instalar dependencias
pip install molecule molecule-plugins[docker] ansible-core
```

### Docker

```bash
# Debian/Ubuntu
sudo apt install docker.io
sudo usermod -aG docker $USER
# Logout/login para aplicar cambios
```

### Ansible Collections

```bash
ansible-galaxy install -r collections/requirements.yml
```

---

## Estructura de Tests

Cada rol tiene su propia estructura de tests Molecule:

```
roles/
  funcional/
    molecule/
      default/
        molecule.yml      # Configuración Molecule
        converge.yml      # Playbook de prueba
        prepare.yml       # Setup de contenedores
        verify.yml        # Validaciones post-instalación
  developer/
    molecule/
      default/
        [mismos archivos]
  sysadmin/
    molecule/
      default/
        [mismos archivos]
```

### Fases de Testing

1. **dependency**: Instala collections de Ansible Galaxy
2. **syntax**: Valida sintaxis de playbooks
3. **create**: Crea contenedores Docker
4. **prepare**: Configura contenedores (usuarios, sudo, systemd)
5. **converge**: Ejecuta el rol completo
6. **idempotence**: Re-ejecuta y verifica 0 cambios
7. **verify**: Valida instalación de paquetes/binarios
8. **destroy**: Destruye contenedores

---

## Ejecución de Tests

### Test Completo

Ejecuta todas las fases (⏱️ ~50-60 min por rol):

```bash
cd roles/sysadmin
source ../../.venv/bin/activate
molecule test
```

### Workflow Iterativo (Recomendado)

Para desarrollo/debugging (⏱️ ~5 min por iteración):

```bash
cd roles/sysadmin
source ../../.venv/bin/activate

# 1. Crear contenedores (una vez)
molecule create

# 2. Iterar cambios rápidamente
molecule converge

# 3. Test completo cuando esté listo
molecule test
```

### Destruir Contenedores

```bash
molecule destroy
```

### Solo Verificación

```bash
molecule verify
```

---

## Workflow Iterativo

### Problema: Tests lentos durante debugging

El ciclo completo `molecule test` toma ~50-60 minutos. Durante debugging de un problema específico, esto es ineficiente.

### Solución: Separar fases

```bash
# Paso 1: Crear contenedores (una vez) - 30 segundos
molecule create

# Paso 2: Iterar cambios - 5 minutos por iteración
# - Editar archivos en roles/sysadmin/tasks/
# - Ejecutar molecule converge
# - Revisar errores
# - Repetir hasta resolver

molecule converge

# Paso 3: Validar idempotencia manualmente
molecule converge  # Segunda ejecución debe mostrar 0 changed

# Paso 4: Test completo final
molecule destroy && molecule test
```

### Beneficios

- ⚡ **25 min → 5 min** por iteración
- 🔄 Mismos contenedores reutilizados
- 🎯 Feedback rápido durante debugging
- ✅ Validación completa al final

### Cuándo destruir y recrear

- Cambios en `prepare.yml` o `molecule.yml`
- Contenedores en estado inconsistente
- Antes del commit final (test limpio)

---

## Resolución de Problemas

### Error: "molecule: command not found"

```bash
# Olvidaste activar el venv
source .venv/bin/activate
```

### Error: "Container is not running"

```bash
# Los contenedores murieron, recrear
molecule destroy
molecule create
```

### Error: "Permission denied" en /tmp/script.sh

**Causa**: Docker monta `/tmp` con flag `noexec`

**Solución**: Usar `bash /tmp/script.sh` en lugar de ejecutar directamente

```yaml
# ❌ Incorrecto
- name: Ejecutar script
  ansible.builtin.script: /tmp/script.sh

# ✅ Correcto
- name: Ejecutar script
  ansible.builtin.shell: bash /tmp/script.sh
  args:
    executable: /bin/bash
```

### Error: Idempotence test failed

**Causa**: Tareas temporales siempre marcan "changed"

**Solución**: Usar `changed_when: false` en operaciones idempotentes

```yaml
# Descarga temporal
- name: Descargar archivo temporal
  ansible.builtin.get_url:
    url: https://example.com/file.gpg
    dest: /tmp/file.gpg
  changed_when: false  # ← Archivo se limpia inmediatamente

# Limpieza
- name: Limpiar archivo temporal
  ansible.builtin.file:
    path: /tmp/file.gpg
    state: absent
  changed_when: false  # ← Operación siempre debe ejecutarse
```

### Error: systemd-resolved en Docker

**Causa**: systemd no funciona completamente en Docker

**Solución**: Skip logic en tareas de DNS

```yaml
- name: Configurar DNS
  ansible.builtin.systemd:
    name: systemd-resolved
    state: started
  when: not (ansible_virtualization_type == 'docker' or skip_dns_config | default(false))
```

### Error: VS Code extension rc=134

**Causa**: V8 crash conocido después de instalar extensiones exitosamente

**Solución**: Permitir rc codes [0, 134]

```yaml
- name: Instalar extensiones VS Code
  ansible.builtin.command: "code --install-extension {{ item }}"
  failed_when: 
    - result.rc not in [0, 134]
    - "'already installed' not in result.stdout"
```

---

## CI/CD

### GitHub Actions (Próximo)

Plan de implementación:

```yaml
# .github/workflows/molecule.yml
name: Molecule Tests

on:
  pull_request:
    paths:
      - 'roles/**'
  push:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        role: [funcional, developer, sysadmin]
        
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          cache: 'pip'
          
      - name: Install dependencies
        run: |
          pip install molecule molecule-plugins[docker] ansible-core
          ansible-galaxy install -r collections/requirements.yml
          
      - name: Run Molecule tests
        run: |
          cd roles/${{ matrix.role }}
          molecule test
```

### Optimizaciones CI

- **Cache de imágenes Docker**: Reducir tiempo de pull
- **Paralelización**: Tests de roles en paralelo
- **Matrix strategy**: Múltiples distros/versiones
- **Artifacts**: Guardar logs de fallos

---

## Variables de Testing

Variables utilizadas en `converge.yml` para skip logic en Docker:

### Funcional
```yaml
skip_gnome_tasks: true         # GNOME no funciona en Docker
skip_dns_config: true          # systemd-resolved problemático
```

### Developer
```yaml
developer_manage_vscode_extensions: false   # Opcional en tests
developer_manage_vscode_defaults: false     # Opcional en tests
developer_skip_docker: false                # Docker instala OK
developer_skip_docker_service: true         # Servicio no inicia en Docker
developer_skip_remote_dev: true             # SSH remoto no necesario
```

### Sysadmin
```yaml
sysadmin_skip_virtualbox: true              # Kernel headers no disponibles
sysadmin_skip_virtualbox_service: true      # Servicio no inicia
sysadmin_skip_nordvpn_service: true         # Servicio no inicia
```

---

## Estadísticas de Tests

### Rol Funcional
- **Tasks ejecutadas**: Variable (base layer)
- **Duración converge**: ~15-20 min
- **Estado**: ✅ PASSING

### Rol Developer
- **Tasks ejecutadas**: 123-126
- **Duración converge**: ~20-25 min
- **Estado**: ✅ PASSING
- **Idempotencia**: 0 changed en segunda ejecución

### Rol Sysadmin
- **Tasks ejecutadas**: 109
- **Duración converge**: ~4-5 min
- **Duración test completo**: ~50-60 min
- **Estado**: ✅ PASSING
- **Idempotencia**: 0 changed en segunda ejecución

**Plataformas testeadas:**
- ✅ Debian 12 (Bookworm)
- ✅ Ubuntu 22.04 (Jammy)

---

## Comandos Útiles

### Debug de contenedores en vivo

```bash
# Listar contenedores Molecule
docker ps -a | grep molecule

# Entrar a contenedor
docker exec -it debian12-sysadmin bash

# Ver logs
docker logs debian12-sysadmin

# Inspeccionar mount /tmp
docker exec debian12-sysadmin mount | grep '/tmp'
```

### Logs de Molecule

```bash
# Con más verbosidad
molecule --debug converge

# Solo mostrar errores
molecule converge 2>&1 | grep -A 10 "FAILED"
```

### Limpieza

```bash
# Destruir todos los contenedores Molecule
molecule destroy

# Limpiar imágenes Docker huérfanas
docker system prune -f

# Eliminar volúmenes no usados
docker volume prune -f
```

---

## Referencias

- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Ansible Testing Strategies](https://docs.ansible.com/ansible/latest/reference_appendices/test_strategies.html)
- [Docker Molecule Driver](https://github.com/ansible-community/molecule-plugins)
- [geerlingguy Docker Images](https://hub.docker.com/u/geerlingguy)

---

## Contribuir

Al añadir nuevas tareas a roles:

1. **Considera Docker compatibility**: Usa skip logic cuando sea necesario
2. **Marca operaciones temporales**: `changed_when: false` en descargas/limpiezas
3. **Testea localmente**: `molecule converge` antes de commit
4. **Valida idempotencia**: Segunda ejecución debe mostrar 0 changed
5. **Actualiza verify.yml**: Añade validaciones de nuevos binarios/paquetes

---

**Última actualización**: Noviembre 2025  
**Maintainer**: Adhoc Team
