# Laboratorio Ansible

Laboratorio de pruebas de ansible, con el objetivo de automatizar la preparación de laptops para puestos Funcionales, Desarrollo y SysAdmins en Adhoc. Para resumir, un espacio experimental y de aprendizaje para preparar "notebooks as a service".  
Para información interna más detallada, procedimiento, pendientes, etc., revisar [este documento](https://docs.google.com/document/d/1iDylKWfjRL9SO_GR_1j7HjQhFixYsFz9Vv3Mi0WstPQ).

### Roles

- funcional > Operaciones, Mesa de Ayuda, Comercial, Administración (aunque usan Windows),
- devs > Sistemas,
- sysadmin > DevOps, SRE, Infraestructura,
- deploy > Implementación express de herramientas para deploy de Infraestructura (k8s).

## Preparación equipo

En principio se puede lanzar el proyecto con un script (que además instala dependencias necesarias). Al ejecutarlo, se instala el rol "Funcional", que es común y necesario para el resto de los roles. Hasta tanto evolucione, se recomienda reiniciar el equipo luego de aplicar cada rol (y continuar):

```bash
# Probando deploy con script
$ sudo apt install curl
$ bash -c "$(curl -fsSL https://raw.githubusercontent.com/ingadhoc/ansible_notebooks/master/launch_project.sh)"
# Revisar o editar script
$ wget https://raw.githubusercontent.com/ingadhoc/ansible_notebooks/master/launch_project.sh
$ sudo bash launch_project.sh
```

### Deploy artesanal ambientes de trabajo (Funcional / Devs / SysAdmin)

```bash
# Dependencias
$ apt install python3-setuptools ansible git stow
# Clonar repositorio con playbooks, tasks, etc.
$ git clone https://github.com/ingadhoc/ansible_notebooks && cd ansible
# Deployar roles
$ ansible-playbook --tags "funcional" local.yml -K --verbose
$ ansible-playbook --tags "devs" local.yml -K --verbose
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
  - social
  - terraform
  - virtualbox
  - zsh
  - omz

### Testeando con [vagrant](vagrantup.com)

_"Vagrant es una herramienta que nos ayuda a crear y manejar máquinas virtuales con un mismo entorno de trabajo. Nos permite definir los servicios a instalar así como también sus configuraciones. Está pensado para trabajar en entornos locales y lo podemos utilizar con shell scripts, Chef, Puppet o Ansible"._

[Discover Vagrant Boxes](https://app.vagrantup.com/boxes/search)

Levantar, ejecutar, acceder, etc.:

```sh
$ vagrant init generic/ubuntu2004
$ vagrant init generic/ubuntu2204
$ vagrant up
$ vagrant ssh
$ logout
$ vagrant box list
generic/ubuntu2004 (virtualbox, 4.1.4)
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
