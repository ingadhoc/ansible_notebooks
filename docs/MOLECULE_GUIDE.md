# Guía: Agregar Tests de Molecule a un Rol

Esta guía te ayuda a crear tests de Molecule para los roles `developer` y `sysadmin`.

## Paso 1: Crear estructura de directorios

```bash
cd roles/developer  # o roles/sysadmin
mkdir -p molecule/default
```

## Paso 2: Copiar archivos base del rol funcional

```bash
# Desde el root del proyecto
cp roles/funcional/molecule/default/molecule.yml roles/developer/molecule/default/
cp roles/funcional/molecule/default/prepare.yml roles/developer/molecule/default/
```

## Paso 3: Editar molecule.yml

Cambiar los nombres de las plataformas:

```yaml
platforms:
  - name: debian12-developer  # Cambiar 'funcional' por el nombre del rol
    image: geerlingguy/docker-debian12-ansible:latest
    # ... resto igual
  
  - name: ubuntu2204-developer  # Cambiar 'funcional' por el nombre del rol
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    # ... resto igual
```

## Paso 4: Crear converge.yml

```yaml
---
- name: Converge
  hosts: all
  become: true

  pre_tasks:
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 600
      changed_when: false

    - name: Install basic dependencies for testing
      ansible.builtin.apt:
        name:
          - sudo
          - gnupg
          - lsb-release
          - software-properties-common
          - systemd
        state: present

  roles:
    # El rol heredará sus dependencias automáticamente
    - role: developer  # o sysadmin
```

## Paso 5: Crear verify.yml

Para el rol **developer**, verificar:

```yaml
---
- name: Verify
  hosts: all
  gather_facts: true
  become: true

  vars:
    required_packages:
      - docker-ce
      - code  # VS Code
      - git
      - python3
      - python3-pip
      - meld
      - tmux

  tasks:
    - name: Verify | Check packages are installed
      ansible.builtin.package_facts:
        manager: apt

    - name: Verify | Assert required packages
      ansible.builtin.assert:
        that:
          - item in ansible_facts.packages
        fail_msg: "Package {{ item }} not installed"
      loop: "{{ required_packages }}"

    - name: Verify | Check Docker service
      ansible.builtin.systemd:
        name: docker
        state: started
        enabled: true
      check_mode: true
      register: docker_service
      failed_when: false

    - name: Verify | Check user in docker group
      ansible.builtin.command: groups testuser
      register: user_groups
      changed_when: false
      failed_when: "'docker' not in user_groups.stdout"

    - name: Verify | Check VS Code extensions
      ansible.builtin.command: code --list-extensions
      become_user: testuser
      register: vscode_extensions
      changed_when: false
      failed_when: vscode_extensions.rc != 0

    - name: Verify | Check Git configuration
      ansible.builtin.command: git config --global user.name
      become_user: testuser
      register: git_config
      changed_when: false
      failed_when: git_config.rc != 0

    - name: Verify | Check SSH key exists
      ansible.builtin.stat:
        path: /home/testuser/.ssh/id_rsa_testuser
      register: ssh_key

    - name: Verify | Assert SSH key created
      ansible.builtin.assert:
        that:
          - ssh_key.stat.exists
```

Para el rol **sysadmin**, agregar verificaciones de:

```yaml
    # Terraform
    - name: Verify | Check Terraform installed
      ansible.builtin.command: terraform version
      changed_when: false

    # Helm
    - name: Verify | Check Helm installed
      ansible.builtin.command: helm version
      changed_when: false

    # VirtualBox (si aplica en contenedor)
    - name: Verify | Check VirtualBox package
      ansible.builtin.package_facts:
        manager: apt
      
    - name: Verify | Assert VirtualBox present
      ansible.builtin.assert:
        that:
          - "'virtualbox' in ansible_facts.packages or 'virtualbox-7.0' in ansible_facts.packages"
```

## Paso 6: Ajustes especiales para contenedores Docker

Algunas tareas no funcionan bien en contenedores Docker:

### Problema: systemd en Docker

Solución en `molecule.yml`:

```yaml
platforms:
  - name: debian12-developer
    # ... resto de config
    privileged: true  # IMPORTANTE
    command: ""  # Dejar vacío para usar systemd
    tmpfs:
      - /run
      - /tmp
```

### Problema: GNOME/GUI en Docker

Las tareas de GNOME (dconf, extensiones) no se pueden testear en contenedores Docker sin display.

Solución: Skip con condición en `converge.yml`:

```yaml
- name: Converge
  hosts: all
  become: true
  
  vars:
    skip_gnome_tasks: true  # Variable para skip de GUI
  
  roles:
    - role: developer
```

Y en las tareas del rol:

```yaml
- name: GNOME | Configure something
  when: not (skip_gnome_tasks | default(false))
  # ... resto de la tarea
```

### Problema: Docker-in-Docker

Para testear Docker dentro del contenedor de test:

```yaml
platforms:
  - name: debian12-developer
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # Socket del host
    privileged: true
```

## Paso 7: Ejecutar los tests

```bash
cd roles/developer
molecule test

# O desde el root con el helper script
./test-role.sh developer
```

## Consejos de Debugging

1. **Crear y mantener contenedor para investigar:**
```bash
molecule create
molecule converge
molecule login
# Investigar dentro del contenedor
```

2. **Ver logs detallados:**
```bash
molecule --debug test
```

3. **Testear solo verificación:**
```bash
molecule create
molecule converge
molecule verify
```

4. **No destruir contenedor después de fallo:**
```bash
molecule test --destroy=never
```

---

## Testing con Múltiples Distribuciones

### Distribuciones Soportadas

**Oficialmente soportadas** (tests por defecto):
- ✅ Debian 12 (Bookworm)
- ✅ Ubuntu 22.04 LTS (Jammy)

**Compatibles** (agregar según necesidad):
- 🟡 Debian 13 (Trixie) - En desarrollo, puede tener limitaciones
- ✅ Ubuntu 24.04 LTS (Noble)

### Agregar Debian 13 y Ubuntu 24.04 a los Tests

#### Opción 1: Edición temporal de molecule.yml

Para testing puntual, edita `roles/ROLNAME/molecule/default/molecule.yml`:

```yaml
platforms:
  # Plataformas existentes
  - name: debian12-ROLNAME
    image: geerlingguy/docker-debian12-ansible:latest
    command: ""
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host
    privileged: true
    pre_build_image: true
    tmpfs:
      - /run
      - /tmp

  - name: ubuntu2204-ROLNAME
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    command: ""
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host
    privileged: true
    pre_build_image: true
    tmpfs:
      - /run
      - /tmp

  # ⬇️ AGREGAR ESTAS PLATAFORMAS
  - name: debian13-ROLNAME
    image: geerlingguy/docker-debian13-ansible:latest
    command: ""
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host
    privileged: true
    pre_build_image: true
    tmpfs:
      - /run
      - /tmp

  - name: ubuntu2404-ROLNAME
    image: geerlingguy/docker-ubuntu2404-ansible:latest
    command: ""
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host
    privileged: true
    pre_build_image: true
    tmpfs:
      - /run
      - /tmp
```

**Ejecutar test con 4 distribuciones**:
```bash
molecule test
# Ejecutará en: debian12, ubuntu2204, debian13, ubuntu2404
```

#### Opción 2: Testing selectivo por plataforma

```bash
# Verificar qué imágenes Docker están disponibles
docker search geerlingguy/docker-debian
docker search geerlingguy/docker-ubuntu

# Crear solo un contenedor específico
molecule create --platform-name ubuntu2404-funcional

# Converge en esa plataforma
molecule converge --platform-name ubuntu2404-funcional

# Verificar idempotencia
molecule converge --platform-name ubuntu2404-funcional

# Verificar tests
molecule verify --platform-name ubuntu2404-funcional

# Limpiar
molecule destroy --platform-name ubuntu2404-funcional
```

#### Opción 3: Crear scenarios separados

Para testing permanente sin afectar el workflow por defecto:

```bash
cd roles/funcional

# Crear scenario para testing extendido
molecule init scenario extended --driver-name docker

# Editar molecule/extended/molecule.yml con las 4 distros
```

**Ejecutar scenarios específicos**:
```bash
molecule test --scenario-name default   # Solo Debian 12 + Ubuntu 22.04
molecule test --scenario-name extended  # Todas las distros
```

### Consideraciones por Distribución

#### Debian 13 (Trixie)

**Estado**: Testing/Unstable (a Noviembre 2025)

**Limitaciones conocidas**:
- 🟡 Algunos paquetes pueden no estar disponibles
- 🟡 Puede requerir ajustes en `packages_exclude_debian_13`
- 🟡 La imagen Docker puede no estar actualizada

**Paquetes problemáticos en Debian 13**:
```yaml
# En vars.yml - ya configurado
packages_exclude_debian_13:
  - stacer
  - tldr
```

**Verificar disponibilidad de imagen**:
```bash
docker pull geerlingguy/docker-debian13-ansible:latest
# Si falla, la imagen aún no existe
```

#### Ubuntu 24.04 LTS (Noble)

**Estado**: Stable (LTS lanzado en Abril 2024)

**Ventajas**:
- ✅ Totalmente estable y soportado hasta 2029
- ✅ Todas las imágenes Docker disponibles
- ✅ Repositories y paquetes actualizados

**Sin limitaciones conocidas** en los roles actuales.

### Matrix Testing en CI/CD

Para GitHub Actions, edita `.github/workflows/molecule.yml`:

```yaml
strategy:
  matrix:
    distro:
      - debian12
      - ubuntu2204
      # Agregar según necesidad:
      # - debian13      # Solo si la imagen está disponible
      # - ubuntu2404    # Recomendado para validación LTS
    python-version:
      - '3.11'
```

**Impacto en tiempo de CI**:
```
2 distros: ~15-20 minutos
3 distros: ~22-30 minutos
4 distros: ~30-40 minutos
```

**Recomendación de estrategia**:
1. **Desarrollo diario**: Solo Debian 12 + Ubuntu 22.04
2. **Pull Requests**: Agregar Ubuntu 24.04
3. **Releases/Quarterly**: Full matrix con las 4 distros (si Debian 13 está disponible)

### Comandos útiles para testing multi-distro

```bash
# Ver todas las plataformas configuradas
molecule list

# Crear todas las plataformas
molecule create

# Converge solo en Debian
molecule converge --platform-name debian12-funcional
molecule converge --platform-name debian13-funcional

# Converge solo en Ubuntu
molecule converge --platform-name ubuntu2204-funcional
molecule converge --platform-name ubuntu2404-funcional

# Test paralelo (requiere molecule-parallel)
pip install molecule-parallel
molecule test --parallel

# Ver logs de un contenedor específico
docker logs debian13-funcional

# Ejecutar comando en un contenedor específico
docker exec -it debian13-funcional bash
```

### Troubleshooting por distro

#### Debian 13 - Paquete no encontrado

```yaml
# Solución: Agregar a packages_exclude_debian_13 en vars.yml
- name: Excluir paquetes problemáticos
  ansible.builtin.set_fact:
    packages_filtered: "{{ packages_system | 
      difference(packages_exclude_debian_13) }}"
  when: ansible_facts['distribution'] == 'Debian' and 
        ansible_facts['distribution_major_version'] == '13'
```

#### Ubuntu 24.04 - Repository key cambió

```yaml
# Las URLs modernas ya usan el formato correcto
- name: Agregar repo con GPG moderno
  ansible.builtin.apt_repository:
    repo: "deb [signed-by=/usr/share/keyrings/key.gpg] https://..."
    state: present
```

---

## Limitaciones conocidas

- **Extensiones GNOME**: No se pueden testear en contenedores sin display
- **Systemd avanzado**: Algunos servicios requieren privilegios especiales
- **VirtualBox**: No se puede instalar/ejecutar dentro de Docker
- **NordVPN**: Requiere kernel modules que no están en contenedor

Para estos casos, mantener tests manuales en VirtualBox.
