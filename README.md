# Proyecto Ansible

Roles de Ansible para automatizar la preparación de laptops para usos funcionales (Mesa de Ayuda, Consultoría, Comercial) y técnicos (Consultoría Técnica, Sistemas, Producto, Infraestructura) en Adhoc. Para información interna más detallada, procedimiento, pendientes, etc., revisar [este documento](https://docs.google.com/document/d/1TY5cQnNCOAxVRk4fFKHlBfWAa5qECUpH1jIjoCY0M4s/).

## Sobre DEBIAN

Intentando evitar quedar atados a Ubuntu / Canonical, comenzamos a experimentar con el uso de Debian12. Adicionalmente notamos que cada imagen de Ubuntu es más pesada y tiene más aplicaciones que la anterior, además de forzar el uso de snap y otras decisiones técnicamente discutibles. Hasta 2024 lo usamos como distribución principal quienes tenemos roles Sysadmin.

## Roles para ejecutar

- funcional > Mesa de Ayuda, Consultoría, Comercial, RRHH
- devs > I + D, Consultoría y Mesa de Ayuda Técnica.
- sysadmin > DevOps, Infraestructura.
- deploy > Implementación express de herramientas para deploy de Infraestructura (k8s).

## Preparación equipo

Se puede lanzar el proyecto con el script [launch_project.sh](https://raw.githubusercontent.com/ingadhoc/ansible_notebooks/main/launch_project.sh) que instala dependencias, clona el repositorio, etc.. Al finalizar ofrece los comandos para implementar cada uno de los roles:

```bash
# Descargar script
$ wget http://bit.ly/adhoc-ansible
# Inspeccionar brevemente
$ nano adhoc-ansible
$ sudo bash adhoc-ansible
```

### Deploy manual

```bash
# Dependencias
$ sudo apt install python3-setuptools ansible git
# Clonar repositorio con playbooks, tasks, etc.
$ git clone git@github.com:ingadhoc/ansible_notebooks.git && cd ansible_notebooks
# Instalar colecciones & dependencias
$ ansible-galaxy install -r collections/requirements.yml
# Para chequear la sintaxis (ahora funcionará)
$ ansible-playbook local.yml --syntax-check
# Para el rol Funcional (ejecución por defecto)
$ ansible-playbook local.yml -K --verbose
# Para el rol Devs (ejecutará funcional -> devs)
$ ansible-playbook local.yml -e "profile_override=devs" -K --verbose
# Para el rol SysAdmin (ejecutará funcional -> devs -> sysadmin)
$ ansible-playbook local.yml -e "profile_override=sysadmin" -K --verbose
# Reiniciar la notebook luego de instalar roles para que apliquen los cambios y configuraciones (docker as root por ejemplo)
```

## TROUBLESHOOTING

### debian > sudoers (adhoc is not in the sudoers file)

```bash
$ su
$ sudo nano /etc/sudoers
# User privilege specification
root  ALL=(ALL:ALL) ALL
# Agregamos:
adhoc  ALL=(ALL:ALL) ALL
```

## Post instalación

Algunos comandos y tareas artesanales pendientes de automatizar:

```bash
$ docker login
# username: adhocsa
# password: token generado en dockerhub
# Configurar ssh en github
$ gh auth login
$ gh ssh-key add /home/$USER/.ssh/private_key_{{ remote_regular_user }}.pub
# Validar: https://github.com/$USER.keys
# Configurar login a Rancher2
$ rancher2 login https://ra.adhoc.ar/v3 --token {bearer-token}
# Configurar kubeconfig

# Login en gcloud (para sysadmin)
$ gcloud auth login
```

### Experimental: Testeando con [vagrant](vagrantup.com)

_"Vagrant es una herramienta que nos ayuda a crear y manejar máquinas virtuales con un mismo entorno de trabajo. Nos permite definir los servicios a instalar así como también sus configuraciones. Está pensado para trabajar en entornos locales y lo podemos utilizar con shell scripts, Chef, Puppet o Ansible"._

[Discover Vagrant Boxes](https://app.vagrantup.com/boxes/search)

Levantar, ejecutar, acceder, etc.:

```sh
$ vagrant init generic/debian12
$ vagrant up
$ vagrant ssh
$ logout
$ vagrant box list
generic/debian12 (virtualbox, 4.1.10)

$ vagrant snapshot save [vm-name] NAME
$ vagrant snapshot save default debian12
==> default: Snapshotting the machine as 'debian12'...
$ vagrant snapshot restore [vm-name] NAME
$ vagrant snapshot restore default vm_debian12

$ vagrant snapshot list
==> default:
debian12
$ vagrant global-status
id       name    provider   state  directory
-----------------------------------------------------------------------
b3fafcb  default virtualbox saved  /home/dib/repositorios/ansible

$ vagrant snapshot push
$ vagrant snapshot pop

$ vagrant destroy
$ vagrant box list
$ vagrant box remove generic/debian12
```

### Ansible Galaxy Collections

https://galaxy.ansible.com/ui/repo/published/community/general/content/module/dconf/#examples
