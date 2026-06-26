# Testing Guide — Ansible Notebooks

Documento único de testing del proyecto. Cubre el setup, el flujo de trabajo con
Molecule, cómo agregar tests a un rol nuevo, troubleshooting y CI.

> Distribución soportada: **Debian 13 (Trixie)**, vía Molecule + Docker
> (`geerlingguy/docker-debian13-ansible`).

## Índice

- [Quick start](#quick-start)
- [Requisitos](#requisitos)
- [Estructura de tests](#estructura-de-tests)
- [Flujo de trabajo](#flujo-de-trabajo)
- [Agregar tests a un rol](#agregar-tests-a-un-rol)
- [Troubleshooting](#troubleshooting)
- [Variables de skip en Docker](#variables-de-skip-en-docker)
- [CI/CD](#cicd)

---

## Quick start

```bash
# 1. Setup del entorno (una sola vez): venv + dependencias + colecciones
make setup

# 2. Correr el test de un rol
./test-role.sh funcional        # o: developer | sysadmin | all

# Atajos
./test-role.sh --check          # verificar que están las dependencias
./test-role.sh --lint           # solo linting (rápido)
```

`make help` lista todos los comandos disponibles (lint, test por rol, ciclo
iterativo de molecule, run local del playbook, etc.).

---

## Requisitos

- **Docker** corriendo y tu usuario en el grupo `docker`.
- **Python 3.11+**.
- Dependencias de testing y colecciones de Ansible.

```bash
# venv (recomendado, evita PEP 668 en Debian)
python3 -m venv .venv && source .venv/bin/activate

pip install -r requirements-dev.txt
ansible-galaxy install -r collections/requirements.yml
```

`make setup` automatiza todo lo anterior.

---

## Estructura de tests

Cada rol tiene su escenario `default` de Molecule:

```text
roles/<rol>/molecule/default/
├── molecule.yml      # Configuración (plataforma Debian 13, driver Docker)
├── prepare.yml       # Setup del contenedor (usuarios, sudo, systemd)
├── converge.yml      # Ejecuta el rol
└── verify.yml        # Aserciones post-instalación (package_facts / assert)
```

`molecule test` corre el pipeline completo de fases:

1. **dependency** — instala colecciones de Galaxy
2. **syntax** — valida sintaxis
3. **create** — crea el contenedor
4. **prepare** — configura el contenedor
5. **converge** — ejecuta el rol
6. **idempotence** — re-ejecuta y exige `changed=0`
7. **verify** — valida instalación de paquetes/binarios
8. **destroy** — limpia

El CI exige que **idempotence** y **verify** pasen estrictamente.

---

## Flujo de trabajo

El ciclo completo (`molecule test`) es lento. Para desarrollo/debugging, separá
las fases y reutilizá el contenedor:

```bash
cd roles/sysadmin
source ../../.venv/bin/activate

molecule create      # una sola vez por sesión
molecule converge    # iterar: editar tasks → converge → repetir
molecule converge    # segunda corrida: validar idempotencia (debe dar changed=0)
molecule verify      # validar aserciones
molecule login       # shell dentro del contenedor para investigar
molecule destroy     # al terminar, o al cambiar prepare.yml / molecule.yml
```

Recreá el contenedor (`destroy` + `create`) cuando cambies `prepare.yml` o
`molecule.yml`, o si quedó en estado inconsistente. Antes del commit, corré el
`molecule test` completo (o `./test-role.sh <rol>`).

Para iterar sobre un subconjunto de tareas usá tags:

```bash
molecule converge -- --tags chrome,gcloud
```

---

## Agregar tests a un rol

1. **Crear la estructura** partiendo de un rol que ya tenga tests:

   ```bash
   mkdir -p roles/<rol>/molecule/default
   cp roles/funcional/molecule/default/{molecule.yml,prepare.yml} \
      roles/<rol>/molecule/default/
   ```

2. **Editar `molecule.yml`** — cambiar el nombre de la plataforma a
   `debian13-<rol>`. El resto del bloque se mantiene (systemd necesita
   `privileged: true`, cgroup montado y `command: ""`):

   ```yaml
   platforms:
     - name: debian13-<rol>
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

3. **`converge.yml`** — ejecuta el rol con las variables de skip de Docker (ver
   [abajo](#variables-de-skip-en-docker)). La herencia de roles se resuelve sola
   vía `meta/main.yml`.

4. **`verify.yml`** — usá `package_facts` + `assert` para paquetes, y `command`
   con `changed_when: false` para chequear binarios/versiones. Regla del
   proyecto: si agregás una herramienta, agregás su verificación.

---

## Troubleshooting

Gotchas reales del proyecto y su causa raíz.

### `/tmp` con `noexec` → "Permission denied" al correr un script

Docker monta `/tmp` con `noexec`. **Nunca** ejecutes un script descargado en
`/tmp` directamente; invocá el intérprete explícito:

```yaml
- name: Ejecutar script
  ansible.builtin.shell: bash /tmp/script.sh
  args:
    executable: /bin/bash
```

Verificá los flags del mount antes de asumir un problema de permisos:
`docker exec <container> mount | grep '/tmp'`.

### Idempotencia falla por `get_url`

`get_url` siempre reporta `changed: true`. Para descargas **temporales** que se
limpian enseguida, usá `changed_when: false`; la idempotencia real se valida en
el estado final del sistema (binario instalado, `.sources` presente), no en los
pasos intermedios. Para los repos APT, el patrón del proyecto guarda el keyring
con `stat` guard y escribe el `.sources` deb822 con `copy` (idempotente por
contenido) — ver [specifications.md](../specifications.md) §3.1.

### `/bin/sh` no es bash → "Illegal option -o pipefail"

En Debian `/bin/sh` es `dash`, que no soporta `pipefail` ni otros bashismos. Si
los necesitás, declará `executable: /bin/bash`. Si no, mejor simplificá el shell.

### systemd no arranca servicios en Docker

Algunos servicios (`systemd-resolved`, etc.) no funcionan completos en
contenedores. Usá skip logic:

```yaml
when: not (ansible_virtualization_type == 'docker' or skip_dns_config | default(false))
```

### VS Code: extensiones devuelven `rc=134`

Crash conocido de V8 al salir **después** de instalar la extensión con éxito
([vscode#159035](https://github.com/microsoft/vscode/issues/159035)). Tratá
`134` como éxito:

```yaml
failed_when:
  - result.rc not in [0, 134]
  - "'already installed' not in result.stdout"
```

### Otros

- **"molecule: command not found"** → activá el venv (`source .venv/bin/activate`).
- **"Cannot connect to Docker daemon"** → `sudo systemctl start docker` y tu
  usuario en el grupo `docker` (relogin).
- **Contenedor en mal estado** → `molecule destroy && molecule create`.

---

## Variables de skip en Docker

Variables que `converge.yml` setea para saltear lo que no aplica en contenedor:

```yaml
# Funcional
skip_gnome_tasks: true                     # GNOME/dconf no corre sin display
skip_dns_config: true                      # systemd-resolved problemático en Docker

# Developer
developer_skip_docker_service: true        # el servicio no inicia en Docker
developer_skip_remote_dev: true            # SSH remoto innecesario en tests
developer_manage_vscode_extensions: false  # opcional en tests

# Sysadmin
sysadmin_skip_virtualbox: true             # requiere kernel headers
sysadmin_skip_virtualbox_service: true     # el servicio no inicia
sysadmin_skip_nordvpn_service: true        # requiere kernel modules
```

> Las tareas de GUI/GNOME deben envolverse siempre con
> `when: not (skip_gnome_tasks | default(false))`.

**Limitaciones conocidas en Docker** (mantener tests manuales en VM para esto):
extensiones de GNOME, VirtualBox y NordVPN (kernel modules).

---

## CI/CD

`.github/workflows/molecule.yml` corre en push/PR a `main`/`develop` y por
`workflow_dispatch`:

1. **lint** — `yamllint`, `ansible-lint` y `--syntax-check` (publica resumen en
   el step summary).
2. **test-funcional / test-developer / test-sysadmin** — `molecule test` por rol
   en Debian 13, dependientes del job de lint. Ante fallo, suben un extracto del
   log al summary.

Para reproducir el pipeline localmente: `make ci` (lint + tests).

---

## Referencias

- [Molecule](https://ansible.readthedocs.io/projects/molecule/)
- [Docker Molecule driver](https://github.com/ansible-community/molecule-plugins)
- [geerlingguy Docker images](https://hub.docker.com/u/geerlingguy)
