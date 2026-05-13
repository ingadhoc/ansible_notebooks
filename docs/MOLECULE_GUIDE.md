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

Cambiar el nombre de la plataforma:

```yaml
platforms:
  - name: debian13-developer  # Cambiar 'developer' por el nombre del rol
    image: geerlingguy/docker-debian13-ansible:latest
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
    # Pulumi
    - name: Verify | Check Pulumi installed
      ansible.builtin.command: pulumi version
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
  - name: debian13-developer
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
  - name: debian13-developer
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

## Distribución soportada

El proyecto se testea únicamente contra **Debian 13 (Trixie)**. La plataforma estándar
definida en `molecule.yml` de cada rol es:

```yaml
platforms:
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
```

### Comandos útiles

```bash
# Ver plataformas configuradas
molecule list

# Crear el contenedor
molecule create

# Converge en la plataforma
molecule converge --platform-name debian13-funcional

# Verificar idempotencia (segunda corrida debe ser changed=0)
molecule converge --platform-name debian13-funcional

# Verificar tests
molecule verify --platform-name debian13-funcional

# Limpiar
molecule destroy

# Ver logs del contenedor
docker logs debian13-funcional

# Ejecutar comando dentro del contenedor
docker exec -it debian13-funcional bash
```

### Troubleshooting

#### Paquete no encontrado en Debian 13

```yaml
# Solución: agregar a packages_exclude_debian_13 en vars.yml
- name: Excluir paquetes problemáticos
  ansible.builtin.set_fact:
    packages_filtered: "{{ packages_system |
      difference(packages_exclude_debian_13) }}"
  when: ansible_facts['distribution'] == 'Debian' and
        ansible_facts['distribution_major_version'] == '13'
```

---

## Limitaciones conocidas

- **Extensiones GNOME**: No se pueden testear en contenedores sin display
- **Systemd avanzado**: Algunos servicios requieren privilegios especiales
- **VirtualBox**: No se puede instalar/ejecutar dentro de Docker
- **NordVPN**: Requiere kernel modules que no están en contenedor

Para estos casos, mantener tests manuales en VirtualBox.
