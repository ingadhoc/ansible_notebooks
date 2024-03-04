# Laboratorio Ansible

Laboratorio usando Ansible, con el objetivo de automatizar la preparación de laptops para usos funcionales (Mesa de Ayuda, Consultoría, Comercial) y técnicos (Sistemas, Producto, Infraestructura) en Adhoc.  
Para información interna más detallada, procedimiento, pendientes, etc., revisar [este documento](https://docs.google.com/document/d/1TY5cQnNCOAxVRk4fFKHlBfWAa5qECUpH1jIjoCY0M4s/).

## Roles para ejecutar

- funcional > Mesa de Ayuda, Consultoría, Comercial
- devs > Sistemas, Producto
- sysadmin > DevOps, Infraestructura,
- deploy > Implementación express de herramientas para deploy de Infraestructura (k8s).

### IMPORTANTE X.ORG

- antes de empezar todo el proceso, es requisito usar Ubuntu en modo x.org (configuración gráfica por incompatibilidad de algunas aplicaciones).
- cuando inicia Ubuntu (o después de cerrar sesión), en la pantalla donde hay que ingresar la contraseña hacer click en la ruedita abajo a la derecha y seleccionar "Ubuntu on Xorg"
- sólo se hace una vez

## Preparación equipo

Se puede lanzar el proyecto con un script, que instala dependencias, clona el repositorio, etc.. Al ejecutarlo, ofrece aplicar el rol "Funcional", que es común y dependencia del resto de los roles:

```bash
# Descargar script
$ wget http://bit.ly/adhoc-ansible
# Inspeccionar brevemente
$ nano adhoc-ansible
$ sudo bash adhoc-ansible
```

### Deploy artesanal (funcional / devs / sysadmin / deploy)

```bash
# Dependencias
$ sudo apt install python3-setuptools ansible git stow
# Clonar repositorio con playbooks, tasks, etc.
$ git clone https://github.com/ingadhoc/ansible_notebooks && cd ansible ansible_notebooks
# Deployar roles EN ESTE ORDEN ya que cada uno es dependencia del siguiente
$ ansible-playbook --tags "funcional" local.yml -K --verbose
$ ansible-playbook --tags "devs" local.yml -K --verbose
# Reiniciar la notebook luego de aplicar el rol dev para que apliquen los cambios y configuraciones (docker as root por ejemplo)
$ ansible-playbook --tags "sysadmin" local.yml -K --verbose
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
# Configurar DockerHub, luego de generar el token en la organización
# https://hub.docker.com/settings/security
```

## Roles > Tasks > Tags

- funcional
  - anydesk
  - branding
  - chrome / firefox
  - ext
  - funcional_fixes
  - gnome
  - language
  - meld
  - packages_funcional
  - python_funcionales
  - ufw
  - shortcuts
  - performance
- devs
  - code
  - docker
  - devs_fixes
  - git
  - kubectl
  - packages_dev
  - yakuake
  - local
  - python
  - lint_hooks
  - rancher
  - ssh
- sysadmin
  - sysadmin_fixes
  - gcloud
  - gh_cli
  - helm_cli
  - kubectl_plugins
  - terraform
  - virtualbox
    - vagrant
  - zsh
  - omz

### Testeando con [vagrant](vagrantup.com)

_"Vagrant es una herramienta que nos ayuda a crear y manejar máquinas virtuales con un mismo entorno de trabajo. Nos permite definir los servicios a instalar así como también sus configuraciones. Está pensado para trabajar en entornos locales y lo podemos utilizar con shell scripts, Chef, Puppet o Ansible"._

[Discover Vagrant Boxes](https://app.vagrantup.com/boxes/search)

Levantar, ejecutar, acceder, etc.:

```sh
$ vagrant init generic/ubuntu2204
$ vagrant up
$ vagrant ssh
$ logout
$ vagrant box list
generic/ubuntu2204 (virtualbox, 4.1.10)

$ vagrant snapshot save [vm-name] NAME
$ vagrant snapshot save default ubuntu2204
==> default: Snapshotting the machine as 'ubuntu2204'...
$ vagrant snapshot restore [vm-name] NAME
$ vagrant snapshot restore default vm_2204

$ vagrant snapshot list
==> default:
ubuntu2204
$ vagrant global-status
id       name    provider   state  directory
-----------------------------------------------------------------------
b3fafcb  default virtualbox saved  /home/dib/repositorios/ansible

$ vagrant snapshot push
$ vagrant snapshot pop

$ vagrant destroy
$ vagrant box list
$ vagrant box remove hashicorp/bionic64
```
