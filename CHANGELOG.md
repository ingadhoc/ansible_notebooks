# Changelog

Registro de cambios relevantes del proyecto. Formato basado en [Keep a Changelog](https://keepachangelog.com/).

---

## [2026-06-26]

### Refactor (PoC): helper reutilizable para repos deb822

- Nuevo `roles/funcional/tasks/_setup_apt_repo.yml` + template
  `roles/funcional/templates/deb822.sources.j2`: centralizan el patrón "keyring GPG +
  repo deb822" (§3.1) que estaba duplicado ~7 veces (docker, code, gh_cli, browsers,
  gcloud, kubectl, nordvpn, adhoccli). Toma una entrada de `*_external_repos` y arma
  keyring + `.sources`; el caller solo instala los paquetes y gatea el `update_cache`
  con `_repo_sources.changed`
- Migrado `funcional/adhoccli.yml` como **prueba de concepto** (68 → 25 líneas). Vars
  de adhoccli normalizadas a campos estructurados deb822 (`uris`/`suites`/`components`/
  `filename`); la salida del `.sources` es byte-idéntica a la anterior
- Pendiente (si se valida el PoC): migrar los repos restantes y resolver el acceso
  cross-rol al helper (developer/sysadmin lo consumirían vía `include_role` +
  `tasks_from`, sin re-ejecutar el rol funcional)
- Verificado: `ansible-lint` perfil `production` y `yamllint` limpios; `--syntax-check`
  OK. El `verify` de molecule de funcional ya chequea el keyring y el `.sources` de adhoc

### Idempotencia: auditoría de roles (dearmor GPG + código muerto)

- `developer/docker.yml` y `developer/code.yml`: el `gpg --dearmor` (gateado por un
  `stat` previo de la clave) usaba `changed_when: false`, así que cuando creaba el
  keyring en la primera instalación reportaba `ok` en vez de `changed`. Cambiado a
  `changed_when: true`, alineándolos con el mismo patrón ya correcto en
  `funcional/browsers.yml`, `funcional/adhoccli.yml` y `funcional/gcloud.yml`
- `developer/prepare_remote_dev.yml`: eliminadas 4 tareas `stat`
  (`developer_ctx_dir`, `developer_16_dir`, `developer_18_dir`, `developer_19_dir`)
  cuyos registros no se usaban en ningún `when` — código muerto. El módulo `git`
  con `update: true` ya hace clone-or-update idempotente
- Auditados además awscli, pulumi, kvm, shortcuts, python, browsers, adhoccli,
  gnome, gcloud, local_dns y los `fixes` de developer/funcional: sin hallazgos
  (módulos idempotentes, `changed_when`/`creates`/`stat` correctos). Cross-check de
  `notify` → todos apuntan a handlers existentes
- Verificado: `ansible-lint` perfil `production` y `yamllint` limpios; `--syntax-check`
  OK. La idempotencia (`changed=0` en la segunda corrida) la valida `molecule` en CI

### Idempotencia: wine-microsip y extensiones de VS Code (sysadmin)

- `funcional/wine-microsip.yml`:
  - `dpkg --add-architecture i386` reportaba `changed` en cada corrida. Ahora se
    gatea contra `dpkg --print-foreign-architectures`. El `apt update_cache` que
    venía después se eliminó por redundante: el refresco del repo WineHQ
    (`cache_valid_time: 0`) ya corre con i386 habilitado y cubre las variantes
    `:i386` (esto quita además un `# noqa: no-handler`)
  - el `get_url` de MicroSIP usaba `force: true`, re-descargando el instalador en
    cada corrida aunque ya estuviera instalado. Ahora se gatea (junto con el
    install) contra un `stat` del `.exe` final
  - `update-desktop-database` (siempre `changed`) ahora corre solo cuando el
    `.desktop` cambió
- `sysadmin/fixes.yml`: la instalación de extensiones de VS Code no tenía el guard
  `rc == 0` que sí tiene `developer/code.yml` (#25). Si `code --list-extensions`
  fallaba, se reinstalaban **todas** las extensiones. Alineado con `code.yml`
- Verificado: `ansible-lint` perfil `production` y `yamllint` limpios; `--syntax-check`
  OK. La idempotencia (`changed=0` en la segunda corrida) la valida `molecule` en CI

### Idempotencia: tareas que reportan sus cambios con veracidad

- `sysadmin/helm.yml` y `sysadmin/nordvpn.yml`: el patrón "descargar a `/tmp` →
  procesar → borrar temporal" reportaba `changed` en cada corrida y lo ocultaba con
  `changed_when: false`. Ahora se gatea contra la existencia del artefacto final
  (binario / keyring) con un `stat` previo, igual que el patrón ya usado en
  `funcional/kubectl.yml`: en la segunda corrida no se ejecuta nada. Además
  `shell` → `command` (sin features de shell; `gpg --dearmor -o`)
- `funcional/user_sysadmin.yml`: quitado `changed_when: false` de la creación del
  directorio de PolicyKit; el módulo `file` ya es idempotente y ahora reporta el
  cambio real
- `funcional/language.yml`: `localectl set-locale`/`set-x11-keymap` reportaban
  siempre `ok` (`changed_when: false`) aunque cambiaran el sistema. Ahora el
  `changed_when` se calcula contra `localectl status`. Se mantiene `failed_when:
  false` (load-bearing: `localectl` puede no estar disponible sin systemd, y hay
  fallback sobre `/etc/default/locale`), ahora documentado
- `developer/code.yml`: `ignore_errors: true` → `failed_when: false` y guard del
  loop con `| default([])`. Si `code --list-extensions` fallaba, se reinstalaban
  **todas** las extensiones en vez de ninguna
- Verificado: `ansible-lint` perfil `production` y `yamllint` limpios en los 5
  archivos; `--syntax-check` OK. La idempotencia (`changed=0` en la segunda corrida)
  la valida `molecule` en CI

### Variables: migración a `vars/main.yml` con prefijo de rol

- Movidas las variables de cada rol de `roles/<rol>/vars.yml` (cargado vía `include_vars` manual) a `roles/<rol>/vars/main.yml` (autocarga estándar de Ansible). Eliminados los `include_vars` redundantes de funcional/developer/sysadmin
- Prefijadas con el nombre del rol todas las variables internas que no lo tenían (~28 en `funcional`: `funcional_packages_*`, `funcional_dconf_settings`, `funcional_branding_*`, `funcional_external_repos`, `funcional_gnome_*`, etc.; `sysadmin_vscode_extension_list`). Cumple `var-naming[no-role-prefix]` y evita colisiones en el namespace global del play
- `remote_regular_user`/`remote_regular_user_uid` se mantienen sin prefijo (alias play-wide compartido a propósito) con `# noqa` documentado
- `deploy` y `freelance_developer` actualizados para cargar las vars del rol de origen desde `vars/main.yml`
- Nueva sección `specifications.md` §3.5 documentando la convención de nombres de variables
- DevContainer: agregados los features `docker-outside-of-docker` (correr Molecule contra el daemon del host) y `github-cli` (gestionar PRs sin instalar `gh` manualmente)
- `ansible-lint local.yml` pasa limpio a profile `production`; syntax-check OK en los 4 perfiles. Validado con `molecule test`: los 4 roles (funcional, developer, sysadmin, freelance_developer) pasan converge + idempotence (changed=0) + verify (exit 0)

### CI/CD: filtrado por paths y branch protection

- El workflow `molecule.yml` ahora filtra qué roles testear según los paths cambiados (`dorny/paths-filter`), respetando el grafo de dependencias: tocar `funcional` re-testea los 3 roles, `developer` re-testea developer+sysadmin, `sysadmin` solo sysadmin; cambios solo-docs no disparan ningún molecule (`lint` sí corre siempre). Evita correr los 3 molecule en cada cambio
- El job `summary` trata `skipped` (rol sin cambios) como OK
- Branch protection en `main`: requiere PR con 1 approval; required checks = `Lint Ansible code` y `Test Summary` (jobs que corren siempre), no los jobs por-rol (que se saltean). Documentado en `docs/TESTING.md`

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
