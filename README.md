# Proyecto de Aprovisionamiento de Notebooks con Ansible

![Molecule CI](https://github.com/ingadhoc/ansible_notebooks/workflows/Molecule%20CI/badge.svg?branch=main)
![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Ansible](https://img.shields.io/badge/ansible-%3E%3D2.15-blue.svg)
![Platforms](https://img.shields.io/badge/platforms-Debian%2012%20%7C%20Ubuntu%2022.04-blue.svg)

## 🎯 Resumen Ejecutivo

Este proyecto utiliza Ansible para automatizar la configuración completa de notebooks para los distintos perfiles de trabajo en Adhoc.

**✨ Nuevo**: Tests automatizados con Molecule para todos los roles. Ver [documentación de testing](docs/TESTING.md).

Para información interna más detallada sobre los objetivos, procedimientos y pendientes, consulta [el documento de diseño interno](https://www.adhoc.inc/odoo/knowledge/2053?debug=1).

---

## Filosofía y Distribuciones Soportadas

Este playbook está diseñado para funcionar sobre instalaciones limpias de **Debian (12+)** y **Ubuntu (22.04+)**.

Priorizamos el uso de Debian para mantener un sistema base limpio, estable y libre de las decisiones comerciales de Canonical (como la imposición de `snap`). Sin embargo, el playbook es totalmente compatible con las versiones LTS de Ubuntu.

---

## Cómo Funciona: Perfiles de Provisión

El sistema está organizado en perfiles jerárquicos. Cada perfil incluye la configuración del anterior, creando un sistema incremental:

* **`funcional` (Base)**: Contiene el software y la configuración esencial para todos los miembros de la empresa (navegadores, herramientas de comunicación, seguridad básica, etc.).
* **`developer`**: Incluye el perfil `funcional` y añade todas las herramientas de desarrollo (Docker, VS Code, Git, Python, kubectl, etc.).
* **`sysadmin`**: Incluye ambos perfiles anteriores y añade herramientas de administración de sistemas e infraestructura (Terraform, gcloud, VirtualBox, etc.).

---

## 🚀 Uso Rápido (Método Recomendado para Equipos Nuevos)

Este es el método preferido para configurar una notebook desde cero. Un único script se encarga de todo.

1. **Descargar el script de arranque:**

   ```bash
   curl -L -o adhoc-ansible https://raw.githubusercontent.com/ingadhoc/ansible_notebooks/main/adhoc-ansible
   ```

2. **Darle permisos de ejecución:**

   ```bash
   chmod +x adhoc-ansible
   ```

3. **Ejecutar el script con `sudo`:**

   ```bash
   sudo ./adhoc-ansible
   ```

El script te guiará con un menú interactivo para que selecciones tu perfil. Se encargará de instalar Ansible, sus dependencias, clonar este repositorio y ejecutar el playbook por ti. Al finalizar, solo necesitarás reiniciar.

---

## 📖 Ejecución Manual y Opciones

Si necesitas volver a ejecutar el playbook en un equipo ya configurado o quieres usar opciones avanzadas, puedes hacerlo manualmente.

**Requisitos previos:**

* Tener `git` y `ansible` (vía `pipx`) instalados.
* Haber clonado este repositorio.

**Comandos:**

```bash
# Navegar al directorio del proyecto
cd ~/repositorios/ansible_notebooks

# (Opcional) Actualizar el repositorio a la última versión
git pull

# (Opcional) Instalar/actualizar las colecciones de Ansible
ansible-galaxy install -r collections/requirements.yml

# --- Ejecutar el perfil deseado ---

# Para el rol Funcional (perfil por defecto)
ansible-playbook local.yml -K --verbose

# Para el rol Developer (ejecutará funcional -> developer)
ansible-playbook local.yml -e "profile_override=developer" -K --verbose

# Para el rol SysAdmin (ejecutará funcional -> developer -> sysadmin)
ansible-playbook local.yml -e "profile_override=sysadmin" -K --verbose

# Para instalar solo herramientas de deploy rápido (ej. kubectl)
ansible-playbook local.yml --tags "deploy" -K --verbose
```

---

## ✅ Tareas Post-Instalación (Manuales)

Después de que Ansible termine, hay algunas acciones que requieren tu intervención para iniciar sesión en servicios específicos.

1. **Configurar SSH en GitHub:**

   * La CLI de `gh` ya estará instalada. Inicia sesión con:

     ```bash
     gh auth login
     ```

   * Sube tu nueva clave SSH. El playbook la creó con el formato `id_rsa_TU_USUARIO@NOMBRE_HOST.pub`.

     ```bash
     # Reemplaza 'dib' y 'dib-adhoc-nb-debian' con tu usuario y hostname
     gh ssh-key add ~/.ssh/id_rsa_dib@dib-adhoc-nb-debian.pub
     ```

2. **Iniciar sesión en Docker Hub:**

   ```bash
   docker login
   # username: adhocsa
   # password: (usar un token generado en Docker Hub)
   ```

3. **Iniciar sesión en Google Cloud (si aplica):**

   ```bash
   gcloud auth login
   ```

---

## 🧪 Testing y Desarrollo

Este proyecto utiliza **Molecule** con Docker para tests automatizados. Los tests se ejecutan automáticamente en GitHub Actions para cada push y pull request.

### Ejecutar tests localmente

```bash
# Instalar dependencias de testing
pip install -r requirements-dev.txt

# Ejecutar tests de un rol específico
./test-role.sh funcional

# Ejecutar todos los tests
./test-role.sh all

# Solo verificar requisitos
./test-role.sh --check

# Solo ejecutar linting
./test-role.sh --lint
```

### Testing con múltiples distribuciones

Por defecto, los tests ejecutan en **Debian 12** y **Ubuntu 22.04**. Para probar con distribuciones adicionales:

```bash
# Usar el Makefile para comandos específicos
make test-ubuntu2404      # Test solo Ubuntu 24.04 LTS
make test-debian13        # Test solo Debian 13 (si disponible)
make test-all-distros     # Test todas las distros configuradas

# Ver plataformas disponibles
make list-platforms

# Descargar imágenes Docker necesarias
make docker-pull-images
```

**Distribuciones soportadas:**
- ✅ **Debian 12 (Bookworm)** - Producción, por defecto
- ✅ **Ubuntu 22.04 LTS (Jammy)** - Producción, por defecto
- 🟡 **Debian 13 (Trixie)** - Testing (algunas limitaciones)
- ✅ **Ubuntu 24.04 LTS (Noble)** - Producción, estable

Para agregar más distribuciones a tus tests, consulta:
- [docs/MOLECULE_GUIDE.md](docs/MOLECULE_GUIDE.md) - Sección "Testing con Múltiples Distribuciones"
- [docs/MULTI_DISTRO_TESTING.md](docs/MULTI_DISTRO_TESTING.md) - Guía completa multi-distro
- [docs/molecule-multi-distro-example.yml](docs/molecule-multi-distro-example.yml) - Configuración de ejemplo
- [roles/funcional/README.md](roles/funcional/README.md) - Testing específico del rol

Para más información sobre testing, consulta [docs/TESTING.md](docs/TESTING.md).

---

## 🔧 Troubleshooting

### Debian: `usuario is not in the sudoers file`

En una instalación mínima de Debian, es posible que tu usuario no sea añadido al grupo `sudo`. Para arreglarlo:

```bash
# 1. Conviértete en root
su -

# 2. Añade tu usuario al grupo sudo (reemplaza 'tu_usuario')
gpasswd -a tu_usuario sudo

# 3. Sal de la sesión de root y reinicia la máquina
exit
sudo reboot
```

### Error: Paquete no disponible en Debian 13

```yaml
# Solución: Agregar a packages_exclude_debian_13 en vars.yml
packages_exclude_debian_13:
  - nombre-paquete-problemático
```

### Error: "Image not found" en Molecule

```bash
# Verificar que la imagen existe
docker search geerlingguy/docker-debian13

# Si no existe, comentar esa plataforma en molecule.yml
```

---

## 🧪 Testing y Desarrollo

Este proyecto incluye tests automatizados con Molecule para validar todos los roles en Debian 12 y Ubuntu 22.04.

### Estado de Tests

| Rol | Tasks | Idempotencia | Debian 12 | Ubuntu 22.04 |
|-----|-------|--------------|-----------|--------------|
| funcional | Variable | ✅ | ✅ | ✅ |
| developer | 123-126 | ✅ | ✅ | ✅ |
| sysadmin | 109 | ✅ | ✅ | ✅ |

### Ejecutar Tests Localmente

```bash
# Setup
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
ansible-galaxy install -r collections/requirements.yml

# Ejecutar tests completos (50-60 min)
cd roles/sysadmin
molecule test

# Workflow iterativo (5 min)
molecule create    # Una vez
molecule converge  # Iterar cambios
molecule test      # Test final
```

### Documentación de Testing

- **[docs/TESTING.md](docs/TESTING.md)** - Guía completa de Molecule y workflow
- **[docs/LESSONS_LEARNED.md](docs/LESSONS_LEARNED.md)** - Troubleshooting y lecciones aprendidas

### CI/CD

Los tests se ejecutan automáticamente en GitHub Actions para cada PR y push a `main`/`develop`. Ver [`.github/workflows/molecule.yml`](.github/workflows/molecule.yml).

---

## 📚 Documentación Adicional

- **[docs/TESTING.md](docs/TESTING.md)** - Guía completa de testing con Molecule
- **[docs/LESSONS_LEARNED.md](docs/LESSONS_LEARNED.md)** - Troubleshooting y debugging
- **[docs/TESTING.md](docs/TESTING.md)** - Estrategias de testing
- **[docs/molecule-multi-distro-example.yml](docs/molecule-multi-distro-example.yml)** - Ejemplo de configuración
- **[roles/funcional/README.md](roles/funcional/README.md)** - Documentación del rol funcional
- **[Makefile](Makefile)** - Todos los comandos disponibles

---
