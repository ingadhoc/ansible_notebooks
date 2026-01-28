# Guía rápida para Developers Freelance (Debian/Ubuntu)

Esta guía es para developers externos que van a aplicar el perfil `freelance_developer` del playbook de aprovisionamiento.

## Requisitos

- Sistema operativo: **Debian 12+** o **Ubuntu 22.04+**.
- Usuario con permisos de **sudo**.
- Conexión a internet estable.

## Opción A (recomendada): Instalación automática con menú

Ejecuta estos comandos en una terminal:

```bash
curl -L -o adhoc-ansible https://raw.githubusercontent.com/ingadhoc/ansible_notebooks/main/launch_project.sh
chmod +x adhoc-ansible
sudo ./adhoc-ansible
```

En el menú, elegir: **Freelance Developer**.

Qué hace este método:
- Instala Ansible (vía `pipx`) y dependencias.
- Clona/actualiza el repo en `~/repositorios/ansible_notebooks`.
- Ejecuta el playbook con el perfil correcto.

Al finalizar, **reiniciar el equipo**.

## Opción B: Ejecución manual (si ya tenés el repo)

```bash
cd ~/repositorios/ansible_notebooks

git pull
ansible-galaxy install -r collections/requirements.yml

ansible-playbook local.yml -e "profile_override=freelance_developer" -K --verbose
```

Tip: si querés ver qué tareas se van a ejecutar sin aplicar cambios, podés listar tasks con:

```bash
ansible-playbook local.yml -e "profile_override=freelance_developer" -K --list-tasks
```

## Qué instala el perfil `freelance_developer`

Resumen (puede variar con el tiempo):
- Herramientas de desarrollo: Git, Python, VS Code, GH CLI.
- Tooling de contenedores y cloud: Docker, kubectl, gcloud.

## Qué NO instala / NO configura (intencionalmente)

- Branding corporativo.
- Tareas de configuración de escritorio/gnome que no aportan al trabajo del freelance.

## Post-instalación (si aplica)

- GitHub (para usar `gh` y/o SSH):
  - `gh auth login`
- Docker Hub (si vas a usar imágenes privadas o rate-limits):
  - `docker login`
- Google Cloud (si el proyecto lo requiere):
  - `gcloud auth login`

## Troubleshooting rápido

- **"usuario is not in the sudoers file" (Debian minimal)**
  - Entrar como root y agregar el usuario al grupo `sudo`, luego reiniciar.

- **Se cortó en el medio / querés reintentar**
  - Re-ejecutar el playbook es válido (Ansible está diseñado para ser idempotente en la mayoría de las tareas):

    ```bash
    cd ~/repositorios/ansible_notebooks
    ansible-playbook local.yml -e "profile_override=freelance_developer" -K --verbose
    ```

## Soporte

Si algo falla, enviar:
- Distribución y versión (`cat /etc/os-release`).
- Las últimas ~50 líneas del output del playbook.
