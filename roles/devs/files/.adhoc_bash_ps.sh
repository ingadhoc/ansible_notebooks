#!/bin/bash

# For customize with your prefer colors and styles go to
# https://gist.github.com/zaoral/4b2c9e86c2eb763d716e67d8a1e7ae88

Purple="\[\033[0;35m\]"
BIPurple="\[\033[1;95m\]"
BIYellow="\[\033[1;93m\]"
Color_Off="\[\033[0m\]"

#UserMachine="$BIYellow[\u@$Yellow\h]"

adhoc_promp_git_branch(){
    local git_branch="$(git branch --show-current 2>/dev/null)";
    local git_ps1_style="";
    local reset='\e(B\e[0m'
    if [ -n "$git_branch" ]; then
        (git diff --quiet --ignore-submodules HEAD 2>/dev/null)
        local git_changed=$?
        if [ "$git_changed" == 0 ]; then
            git_ps1_style='\e[1;32m'; # Light Green
        else
            git_ps1_style='\e[1;91m'; # red
        fi
        git_ps1_style=$git_ps1_style"⫱"$git_branch$reset
    fi
    echo -en $git_ps1_style
}

adhoc_promp_last_cmd_status(){
    if [[ $? == 0 ]]; then
        return
    fi
    local red='\e[1;31m'
    local reset='\e(B\e[0m'
    echo -en "${red}‼${reset} "
}

adhoc_promp_user(){
    local userColor='\e[1;30m\e[1;102m'
    # local userColor='\e[32m'
    local reset='\e(B\e[m'
    echo -en "${userColor} \u ${reset}"
}

adhoc_promp_gcloud(){
    local gcloud_config_path="$HOME/.config/gcloud"
    if [[ ! -f "$gcloud_config_path/active_config" ]]; then
        return
    fi
    local active_config=$(cat $gcloud_config_path/active_config)
    local active_config_file="$gcloud_config_path/configurations/config_$active_config"
    if [[ ! -f "$active_config_file" ]]; then
        return
    fi
    local account=$(grep 'account' $active_config_file | sed 's/.*= //')
    local project=$(grep 'project' $active_config_file | sed 's/.*= //')

    # switch () {
    #     case :

    # }
    ## TODO: MARK PROD WITH RED BACKGROUND
    # local gcloudColor='\e[96m'
    local gcloudColor='\e[1;30m\e[1;106m'
    local reset='\e(B\e[m'

    echo -en "${gcloudColor} g:$account:$project ${reset}"
}

adhoc_promp_k8s(){
    local gcloud_config_path="$HOME/.kube/config"
    if [[ ! -f "$gcloud_config_path" ]]; then
        return
    fi
    local current_context="$(grep 'current-context' $gcloud_config_path | sed 's/.*: //')";
    if [ ! -n "$current_context" ]; then
        return
    fi
    local ps1_style="";
    local reset='\e(B\e[0m'
    case $current_context in
        adhocprod )
            local ps1_style='\e[0;33m\e[0;41m'
        ;;
        * )
            local ps1_style='\e[0;93m'
        ;;
    esac
    echo -en "${ps1_style} k:$current_context ${reset}"
}

adhoc_promp_rancher(){
    local config_path="$HOME/.rancher/cli2.json"
    if [[ ! -f "$config_path" ]]; then
        return
    fi
    local current_cluster=$(jq '.CurrentServer' $config_path)
    local current_cluster_id=\"$(jq -c ".Servers.${current_cluster}.project" $config_path | tr -d \" | cut -d':' -f1)\"
    local current_context=$(jq ".Servers.${current_cluster}.kubeConfigs | to_entries[] | select(.key | contains("$current_cluster_id")) | .value.\"current-context\"" $config_path | tr -d \")
    if [ ! -n "$current_context" ]; then
        return
    fi
    local ps1_style="";
    local reset='\e(B\e[0m'
    case $current_context in
        adhocprod|europe-cluster )
            local ps1_style='\e[0;33m\e[0;41m'
        ;;
        * )
            local ps1_style='\e[0;93m'
        ;;
    esac
    echo -en "${ps1_style} R:$current_context ${reset}"
}

adhoc_promp_path(){
    local pathColor='\e[1;30m\e[1;106m'
    local reset='\e(B\e[m'
    echo -en "${pathColor} \w ${reset}"
}

PS1="\$(adhoc_promp_last_cmd_status)$(adhoc_promp_user)"

if command -v gcloud &> /dev/null; then
    PS1=$PS1"\$(adhoc_promp_gcloud)"
fi

# if command -v kubectl &> /dev/null; then
#     PS1=$PS1"\$(adhoc_promp_k8s)"
# fi

if command -v rancher2 &> /dev/null; then
    PS1=$PS1"\$(adhoc_promp_rancher)"
fi

PS1=$PS1"$(adhoc_promp_path)"

if command -v git &> /dev/null; then
    PS1=$PS1" \$(adhoc_promp_git_branch)"
fi

PS1=$PS1"\n\$ "
