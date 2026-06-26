# Changelog

Registro de cambios relevantes del proyecto. Formato basado en [Keep a Changelog](https://keepachangelog.com/).

---

## [2026-06-26]

### Variables: migración a `vars/main.yml` con prefijo de rol

- Movidas las variables de cada rol de `roles/<rol>/vars.yml` (cargado vía `include_vars` manual) a `roles/<rol>/vars/main.yml` (autocarga estándar de Ansible). Eliminados los `include_vars` redundantes de funcional/developer/sysadmin
- Prefijadas con el nombre del rol todas las variables internas que no lo tenían (~28 en `funcional`: `funcional_packages_*`, `funcional_dconf_settings`, `funcional_branding_*`, `funcional_external_repos`, `funcional_gnome_*`, etc.; `sysadmin_vscode_extension_list`). Cumple `var-naming[no-role-prefix]` y evita colisiones en el namespace global del play
- `remote_regular_user`/`remote_regular_user_uid` se mantienen sin prefijo (alias play-wide compartido a propósito) con `# noqa` documentado
- `deploy` y `freelance_developer` actualizados para cargar las vars del rol de origen desde `vars/main.yml`
- Nueva sección `specifications.md` §3.5 documentando la convención de nombres de variables
- DevContainer: agregado el feature `docker-outside-of-docker` para poder correr los tests de Molecule contra el daemon del host
- `ansible-lint local.yml` pasa limpio a profile `production`; syntax-check OK en los 4 perfiles. **Pendiente: validación con `molecule test` tras rebuild del devcontainer**

### Limpieza de estructura: documentación, scripts y consistencia

- **Documentación consolidada**: testing unificado en un único `docs/TESTING.md`
  (absorbe `TESTING.md`, `QUICKSTART_TESTING.md`, `docs/MOLECULE_GUIDE.md` y
  `docs/LESSONS_LEARNED.md`, ahora eliminados). `docs/` pasa de 6 a 3 archivos
- Eliminado `docs/CHANGELOG_MEJORAS_FUNCIONAL.md` (obsoleto: describía el patrón
  `apt_key` y referenciaba archivos inexistentes). El changelog vive solo en la raíz
- README adelgazado: delega perfiles/freelance en `docs/PROFILES.md` y
  `docs/FREELANCE_DEVELOPER.md`; eliminados todos los enlaces rotos y un fence colgante
- `specifications.md` §3.1 actualizado al patrón real deb822 (`.sources` con `copy`),
  reemplazando la descripción obsoleta de `apt_repository`/`.list`
- **Scripts**: eliminados `setup-dev.sh` y `setup-testing.sh` (huérfanos y
  duplicaban `make setup` / `make install-hooks`). `test-role.sh` se mantiene como
  runner de tests
- **`assign_laptop.yml`** alineado a la spec: FQCN, `true/false`, `failed_when`
  en lugar de `ignore_errors`. Pasa `ansible-lint` con perfil `production`
- **Rol `deploy`** autocontenido: carga explícita de `funcional/vars.yml` y comentario
  que documenta por qué los `import_tasks` usan ruta relativa (evitar la cascada de
  dependencias de `meta/main.yml`)

---

## [2026-06-25]

### Limpieza de warnings de ansible-lint (~180 → 13)

- Alineada la config `.yamllint` con los requisitos de ansible-lint (`comments-indentation`, `braces`, `octal-values`) para habilitar el modo `--fix`
- Resueltos vía autofix determinístico: `yaml` (formato, 63) y `fqcn` (nombres de módulo completos, 12)
- `no-handler` (8): las tareas `update_cache when ...changed` se fusionaron en la propia tarea de instalación con `update_cache: true` + `cache_valid_time` condicional (`0` cuando el `.sources` cambió para forzar refresh, `apt_cache_valid_time` si no) — preserva orden e idempotencia y evita refrescar APT en cada corrida sin cambios
- `no-changed-when` (10) y `name` (1): `changed_when` explícito en comandos imperativos y nombre al play de `assign_laptop.yml`
- `var-naming` (64): registers y set_facts de los roles renombrados con su prefijo de rol (`funcional_`, `developer_`, `sysadmin_`); en `molecule/` se renombró lo seguro y se anotó con `# noqa` los falsos positivos (override de `ansible_env`, vars cross-role en converge)
- Restan 13 warnings de menor prioridad (`ignore-errors`, `partial-become`, `risky-shell-pipe`, `command-instead-of-module`) que requieren revisión caso por caso
- `ansible-lint local.yml` (lo que corre el CI) pasa limpio a profile `production`

### Repositorios APT — migración de `apt_repository` al formato deb822 (`.sources`)

- Migrados los 8 repositorios externos del módulo deprecado `ansible.builtin.apt_repository` (será removido en ansible-core 2.25) al formato moderno deb822, en los roles `funcional` (gcloud, kubectl, chrome, adhoccli), `developer` (docker, vscode, github-cli) y `sysadmin` (nordvpn)
- Los archivos `.sources` se escriben con `ansible.builtin.copy` en vez del módulo `ansible.builtin.deb822_repository`: idempotencia real (comparación por contenido), sin la dependencia `python3-debian` y sin las rarezas de idempotencia del módulo con `architectures` en contenedores Debian 13
- Cada tarea elimina primero el archivo `.list` legacy para evitar repos configurados por duplicado en máquinas ya provisionadas
- Eliminados los `stat` guard manuales: `copy` ya es idempotente de forma nativa
- `github_cli` y `nordvpn` ahora usan campos estructurados (uris/suites/components) en vez de la línea `deb ...` completa
- Endurecida la descarga de la llave GPG de adhoc (`get_url` con reintentos + `command` para el dearmor) en lugar del frágil `wget -qO - | gpg` sin reintentos
- Actualizado el `verify.yml` de molecule del rol `funcional` para verificar archivos `.sources` en lugar de `.list`

---

## [2026-05-16]

### Devcontainer

- Corregido `ansible.python.interpreterPath` para apuntar al venv real (`/home/appuser/ansible-venv/bin/python3`) en lugar del Python del sistema
- `postCreateCommand` ahora instala `requirements-dev.txt` (molecule, pytest-testinfra, etc.) y corre `pre-commit install` además de `ansible-galaxy`
- Agregadas extensiones: `shellcheck`, `markdownlint`, `ms-python.python`
- Activada validación y autocompletado de módulos Ansible en el editor
- Agregadas variables de entorno `ANSIBLE_FORCE_COLOR` para output coloreado en terminal
- Agregado forwarding del SSH agent del host al container (necesario para conectar a hosts remotos)
- Alineado el editor con las reglas de pre-commit: `trimTrailingWhitespace`, `insertFinalNewline`

---

## [2025-11-01]

### Rol `funcional` — mejoras generales

- Idempotencia completa: segunda ejecución sin cambios
- Eliminado módulo deprecado `apt_key`; migrado a GPG keyrings modernos
- Variables de URLs externas centralizadas en `vars.yml`
- Cobertura de tests ampliada: 22 → 29 verificaciones
- Agregados handlers para UFW, fail2ban, sshd, systemd-resolved, GDM
- Migración `google-cloud-sdk` → `google-cloud-cli`
- Pre-commit hooks configurados (yamllint, ansible-lint, detect-secrets, markdownlint)
- Makefile con 20+ comandos de desarrollo y testing
- GitHub Actions con caché de pip y colecciones (~30% más rápido en CI)
