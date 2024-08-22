# Verifica si está instalado Anydesk, sino instala, y muestra el ID
alias adhoc-anydesk='sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/adhoc-dev/sysadmin-tools/main/check_anydesk.sh)"'

# Para ejecutar fácilmente el mantenimiento preventivo de Adhoc en las notebooks
alias mantenimiento='sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/adhoc-dev/sysadmin-tools/main/script_mantenimiento_post.sh)"'

# Alias para k8s, rancher2, etc.
alias k='rancher2 kubectl'

# Alias para el comando / scrip r2 (rancher2 y k8s)
alias r2='/home/$USER/repositorios/team-tools/devops/rke_byadhoc.sh'

alias kgp="rancher2 kubectl get po"
alias tf="terraform"
alias kns="kubens"
alias kgfp='rancher2 kubectl get pods -A -o json | jq '"'"'.items[] | select(.status.phase != "Running" and .status.phase != "Completed" and .status.phase != "Succeeded") | {namespace: .metadata.namespace, name: .metadata.name, status: .status.phase}'"'"''
