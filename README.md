# Proyecto de Aprovisionamiento de Notebooks con Ansible

Este proyecto utiliza Ansible para automatizar la configuración completa de notebooks para los distintos perfiles de trabajo en Adhoc.

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
    curl -L -o adhoc-ansible [https://raw.githubusercontent.com/ingadhoc/ansible_notebooks/main/adhoc-ansible](https://raw.githubusercontent.com/ingadhoc/ansible_notebooks/main/adhoc-ansible)
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

3. **Iniciar sesión en Rancher (si aplica):**

    ```bash
    rancher login [https://ra.adhoc.ar/v3](https://ra.adhoc.ar/v3) --token {bearer-token}
    ```

4. **Iniciar sesión en Google Cloud (si aplica):**

    ```bash
    gcloud auth login
    ```

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
