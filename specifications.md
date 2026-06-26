# Specifications: Ansible Notebooks Provisioning

## 1. Project Overview

Este repositorio contiene la automatización oficial de Adhoc para aprovisionar estaciones de trabajo (notebooks). Utiliza Ansible para configurar sistemas operativos desde cero, garantizando entornos consistentes, seguros y auditables.

**Filosofía Core:**

- **Debian-Only:** Soporte exclusivo para Debian 13 (Trixie). Sistema base limpio, estable y libre de decisiones comerciales de Canonical.
- **Idempotencia estricta:** Ejecutar el playbook múltiples veces sobre el mismo equipo debe resultar en `changed=0`.
- **Testing Continuo:** Todo rol debe ser testeable en entornos aislados vía Molecule + Docker.
- **Automatización sobre intervención manual:** Evitar pasos manuales post-instalación siempre que sea posible.

---

## 2. Perfiles de Provisión (Roles Architecture)

El sistema utiliza una arquitectura de roles jerárquica basada en el perfil del usuario.
*Importante:* Para evitar duplicación, los roles superiores incluyen (`include_role` / `import_tasks`) tareas de los roles base.

1. **`funcional` (Base):**
   - **Scope:** Software esencial, navegadores, seguridad básica (UFW, fail2ban, SSH hardening), configuración de DNS (systemd-resolved) y branding corporativo de escritorio (GNOME).
   - **Target:** Todos los usuarios corporativos.

2. **`developer`:**
   - **Scope:** Hereda de `funcional`. Agrega tooling de desarrollo: Docker, VS Code, Git (hooks globales), Python (venvs), kubectl, extensiones y configuraciones de entorno Odoo.
   - **Target:** Desarrolladores internos de Adhoc.

3. **`freelance_developer`:**
   - **Scope:** Subconjunto selectivo. Incluye herramientas de desarrollo (Git, Python, Docker, VS Code, Cloud CLIs) pero **excluye explícitamente** configuraciones corporativas, branding de GNOME y restricciones de red severas.
   - **Target:** Desarrolladores externos/contratistas.

4. **`sysadmin`:**
   - **Scope:** Hereda de `developer`. Agrega tooling de infraestructura y SRE: Pulumi, Helm, KVM/QEMU, NordVPN y temas específicos de sistema (Numix).
   - **Target:** Equipo DevOps / SRE.

---

## 3. Architectural & Implementation Guidelines (Reglas de Código)

Cualquier contribución (humana o IA) DEBE adherirse a los siguientes patrones ya establecidos:

### 3.1. Patrón Moderno de Repositorios APT (deb822 `.sources`)

Está estrictamente prohibido usar los módulos obsoletos `apt_key` y
`apt_repository` (este último será removido en ansible-core 2.25). Tampoco se usa
el módulo `deb822_repository` (depende de `python3-debian` y tiene rarezas de
idempotencia con `architectures` en contenedores). Todo repositorio externo debe
seguir este patrón:

1. Validar si el keyring existe (`stat`).
2. Descargar la llave GPG a `/tmp` (`get_url`, solo `when: not <keyring>.stat.exists`).
3. Convertir con `gpg --dearmor` hacia `/usr/share/keyrings/` o `/etc/apt/keyrings/`.
4. Borrar archivo temporal de `/tmp`.
5. Eliminar el `.list` legacy si existe (`file: state=absent`) para no duplicar el
   repo en máquinas ya provisionadas.
6. Escribir el archivo `.sources` (formato deb822) con `ansible.builtin.copy` y
   campos estructurados (`Types`, `URIs`, `Suites`, `Components`, `Signed-By`).
   `copy` es idempotente por contenido, así que no necesita `stat` guard previo.
7. Actualizar cache condicionalmente (`when: repo_added.changed`).

Las URLs, claves y rutas de keyring de cada repo se centralizan en el
`external_repos` de `vars.yml` del rol. Ver implementación de referencia en
`roles/funcional/tasks/kubectl.yml` y `gcloud.yml`.

### 3.2. Idempotencia Real vs Temporal

- Si una tarea manipula archivos temporales o hace limpiezas que no alteran el estado funcional del sistema, DEBE usar `changed_when: false`.
- La idempotencia se valida evaluando el estado final del sistema (ej. si el binario está instalado), no en los pasos intermedios de descarga.

### 3.3. Entornos Docker y Restricciones (Para Molecule)

El código debe estar preparado para correr dentro de contenedores Docker durante el testing (CI/CD):
- **GUI / GNOME Tasks:** Todas las tareas relacionadas con `dconf`, fondos de pantalla o UI deben envolverse con `when: not (skip_gnome_tasks | default(false))`.
- **/tmp Noexec:** Docker monta `/tmp` con flag `noexec`. Los scripts descargados allí NUNCA deben ejecutarse directamente. Usar intérprete explícito: `ansible.builtin.shell: bash /tmp/script.sh` con `args: { executable: /bin/bash }`.
- **Systemd:** Ciertos servicios (ej. `systemd-resolved`) no funcionan en Docker. Usar skip logic: `when: not (ansible_virtualization_type == 'docker')`.
- **Shell Scripts:** `/bin/sh` en Debian apunta a `dash` (no soporta `pipefail`). Si usas bashismos, define explícitamente `executable: /bin/bash`.

### 3.4. Manejo de Errores y Bugs Conocidos

- **VS Code Extensions:** La instalación de extensiones a veces provoca un crash de V8 al finalizar (return code `134`). Esto es esperado. Las tareas de VS Code deben aceptar `rc not in [0, 134]`.

---

## 4. Testing Strategy (Molecule)

- **Driver:** Docker (`geerlingguy/docker-debian13-ansible`).
- **Plataforma:** Debian 13 (Trixie).
- **Fases críticas:** El CI exige que la fase `idempotence` pase estrictamente (0 changes en el segundo run) y que la fase `verify` valide aserciones mediante `ansible.builtin.assert` o `package_facts`.

**Workflow de Desarrollo Iterativo para la IA/Dev:**
En lugar de correr el ciclo completo, para desarrollo se exige el flujo:
`molecule create` -> `molecule converge` (repetir hasta que funcione) -> `molecule verify`.

---

## 5. Reglas para Agentes de IA (Claude/Cursor)

1. **NO "Vibe Coding":** Antes de instalar un nuevo paquete o servicio, revisa este archivo. Aplica el patrón APT correspondiente si requiere un repositorio de terceros.
2. **Linting estricto:** El proyecto usa pre-commit hooks (`yamllint`, `ansible-lint`). Escribe YAML canónico (sin abreviaturas raras de diccionarios, usando FQCN como `ansible.builtin.apt`).
3. **Variables:** Las URLs de repositorios, GPG keys y listas de paquetes deben centralizarse en `vars.yml` del rol correspondiente, NUNCA hardcodeadas en los `tasks/main.yml`.
4. **Verificación:** Si agregas una herramienta (ej. `terraform`), DEBES agregar su correspondiente check de instalación y versión en `molecule/default/verify.yml`.
5. **Changelog:** Todo cambio relevante al proyecto debe registrarse en `CHANGELOG.md` (raíz del repo) bajo la fecha del día. Se considera relevante cualquier cambio de comportamiento, nueva herramienta, decisión de arquitectura, o modificación de infraestructura de desarrollo (devcontainer, CI, tooling). No se registran correcciones de typos ni refactors internos sin impacto funcional.

---
*Última actualización: Marzo 2026. Documento "Spec-Anchored" para el proyecto Ansible Notebooks de Adhoc.*
