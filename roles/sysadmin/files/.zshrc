# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Which plugins would you like to load?
plugins=(z git docker zsh-syntax-highlighting zsh-autosuggestions kubectl colorize command-not-found docker docker-compose gcloud python pip history sudo dirhistory)

#source ~/.oh-my-zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
source $ZSH/oh-my-zsh.sh

# User configuration
export DEFAULT_USER="$(whoami)"
# export MANPATH="/usr/local/man:$MANPATH"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Git-AdHoc Prompt
#source /home/$USER/.prompt_git >> ~/.zshrc

alias upd='sudo apt update'
alias upg='sudo apt upgrade'
alias untar='tar -zxvf' # Unpack .tar file
alias dps='docker ps --format="table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'

# Alias para el comando / scrip r2 (rancher2 y k8s)
alias r2='/home/$USER/repositorios/team-tools/devops/rke_byadhoc.sh'
complete -C /home/$USER/repositorios/team-tools/devops/rke_byadhoc.sh r2

# kubectl
source <(kubectl completion zsh)
alias k='kubectl'
alias kubectl="kubecolor"
alias ktx="kubectx"
alias kedit='KUBE_EDITOR="nano" kubectl edit'
alias kgp="k get po"
alias tf="terraform"
alias kns="kubens"
alias kgfp='kubectl get pods -A -o json | jq '"'"'.items[] | select(.status.phase != "Running" and .status.phase != "Completed" and .status.phase != "Succeeded") | {namespace: .metadata.namespace, name: .metadata.name, status: .status.phase}'"'"''
compdef __start_kubectl k
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# kube-ps1: Kubernetes prompt for bash and zsh
source /home/$USER/.oh-my-zsh/plugins/kube-ps1/kube-ps1.plugin.zsh
PROMPT='$(kube_ps1)'$PROMPT


autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform

# zsh-gcloud-prompt: Show current gcloud config in zsh prompt
autoload -Uz colors; colors
source ~/.oh-my-zsh/custom/plugins/zsh-gcloud-prompt/gcloud.zsh
RPROMPT='%{$fg[cyan]%}($ZSH_GCLOUD_PROMPT)%{$reset_color%}'

# Enable Helm experimental support for OCI images
# https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster/rancher-on-gke
export HELM_EXPERIMENTAL_OCI=1

# Para ejecutar fácilmente el mantenimiento preventivo de Adhoc en las notebooks
alias mantenimiento='sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/adhoc-dev/sysadmin-tools/main/script_mantenimiento_post.sh)"'
