# Changelog

Registro de cambios relevantes del proyecto. Formato basado en [Keep a Changelog](https://keepachangelog.com/).

---

## [2026-06-25]

### Limpieza de warnings de ansible-lint (~180 → 13)

- Alineada la config `.yamllint` con los requisitos de ansible-lint (`comments-indentation`, `braces`, `octal-values`) para habilitar el modo `--fix`
- Resueltos vía autofix determinístico: `yaml` (formato, 63) y `fqcn` (nombres de módulo completos, 12)
- `no-handler` (8): las tareas `update_cache when ...changed` se fusionaron como `update_cache: true` en la propia tarea de instalación (preserva orden e idempotencia; elimina los `register` intermedios)
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

Ver detalle técnico en [docs/CHANGELOG_MEJORAS_FUNCIONAL.md](docs/CHANGELOG_MEJORAS_FUNCIONAL.md).
