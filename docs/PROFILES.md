# Perfiles de provisión (guía de elección)

Este proyecto instala un entorno de trabajo completo en **Debian 12+** y **Ubuntu 22.04+** usando Ansible.

La idea central es simple:
- Elegís un **perfil** (rol) según tu tipo de trabajo.
- Corrés el playbook.
- Reiniciás el equipo.

## TL;DR (si tenés 30 segundos)

- ¿Sos **developer freelance/externo**? Usá `freelance_developer`.
- ¿Sos **developer interno** y querés el stack completo corporativo? Usá `developer`.
- ¿Sos **SRE/infra**? Usá `sysadmin`.
- ¿Solo querés lo mínimo común? Usá `funcional`.

## Árbol de decisión (rápido)

1) ¿Necesitás herramientas de **infra/SRE** (ej. Terraform/Helm/VPN/KVM/etc.)?
- Sí → `sysadmin`
- No → seguir

2) ¿Sos **freelance/externo** y querés evitar configuración corporativa de escritorio/branding?
- Sí → `freelance_developer`
- No → seguir

3) ¿Vas a desarrollar y necesitás tooling completo (VS Code, Git, Python, Docker, kubectl, etc.)?
- Sí → `developer`
- No → `funcional`

## Matriz conceptual (para entender el alcance)

Esta tabla es intencionalmente conceptual (orientada a decisión). El detalle fino puede cambiar con el tiempo y vive en los roles.

| Perfil | Base de workstation | Tooling de dev | Contenedores (Docker) | Cloud CLI (kubectl/gcloud) | Desktop/branding corporativo | Herramientas infra/SRE |
|---|---|---|---|---|---|---|
| `funcional` | Sí | No | No | No | Sí | No |
| `developer` | Sí | Sí | Sí | Sí | Sí (por herencia) | No |
| `freelance_developer` | Sí (subset) | Sí (subset) | Sí | Sí | No | No |
| `sysadmin` | Sí | Sí | Sí | Sí | Sí (por herencia) | Sí |

## Opción recomendada: bootstrap interactivo

Este método instala dependencias, Ansible (vía `pipx`), clona el repo y ejecuta el playbook.

```bash
curl -L -o adhoc-ansible https://raw.githubusercontent.com/ingadhoc/ansible_notebooks/main/launch_project.sh
chmod +x adhoc-ansible
sudo ./adhoc-ansible
```

Luego elegí el perfil en el menú.

## Ejecución manual (cuando ya tenés el repo)

```bash
cd ~/repositorios/ansible_notebooks

git pull
ansible-galaxy install -r collections/requirements.yml
```

### Ejecutar `funcional`

```bash
ansible-playbook local.yml -K --verbose
```

### Ejecutar `developer`

```bash
ansible-playbook local.yml -e "profile_override=developer" -K --verbose
```

### Ejecutar `freelance_developer`

```bash
ansible-playbook local.yml -e "profile_override=freelance_developer" -K --verbose
```

### Ejecutar `sysadmin`

```bash
ansible-playbook local.yml -e "profile_override=sysadmin" -K --verbose
```

## Notas importantes

- El playbook pide contraseña de sudo (`-K`).
- Si se corta a mitad de camino, normalmente podés **re-ejecutar**: Ansible está pensado para ser mayormente idempotente.
- Al finalizar una instalación grande, **reiniciar** suele ser lo correcto (servicios, grupos, PATH, etc.).

## Documentación relacionada

- Guía copy/paste para externos: [docs/FREELANCE_DEVELOPER.md](FREELANCE_DEVELOPER.md)
- Testing (Molecule): [docs/TESTING.md](TESTING.md)
