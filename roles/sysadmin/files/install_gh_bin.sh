#!/bin/bash

_getLastVersion() {
    local url
    url=$(curl -s -o /dev/null -w "%{redirect_url}\n" https://github.com/$1/releases/latest)
    echo "${url##*/}"
}

REPO_NAME=FairwindsOps/pluto
LastVersion=$(_getLastVersion $REPO_NAME)
LastPureVersion="${LastVersion#v}"
wget -O /tmp/pluto.tar.gz https://github.com/$REPO_NAME/releases/download/${LastVersion}/pluto_${LastPureVersion}_linux_amd64.tar.gz
tar -xzvf /tmp/pluto.tar.gz -C /usr/bin
rm /tmp/pluto.tar.gz

REPO_NAME=rancher/rke
LastVersion=$(_getLastVersion $REPO_NAME)
wget -O /usr/bin/rke https://github.com/$REPO_NAME/releases/download/${LastVersion}/rke_linux-amd64
chmod +x /usr/bin/rke

REPO_NAME=robscott/kube-capacity
LastVersion=$(_getLastVersion $REPO_NAME)
wget -O /tmp/kube-capacity.tar.gz https://github.com/$REPO_NAME/releases/download/${LastVersion}/kube-capacity_${LastVersion}_linux_x86_64.tar.gz
tar -xzvf /tmp/kube-capacity.tar.gz -C /usr/bin
rm /tmp/kube-capacity.tar.gz

REPO_NAME=derailed/popeye
LastVersion=$(_getLastVersion $REPO_NAME)
wget -O /tmp/popeye.tar.gz https://github.com/$REPO_NAME/releases/download/${LastVersion}/popeye_linux_amd64.tar.gz
tar -xzvf /tmp/popeye.tar.gz -C /usr/bin
rm /tmp/popeye.tar.gz
