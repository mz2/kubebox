#!/bin/bash

set -e pipefail

(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' > ~/.bash_profile
source ~/.bash_profile

kubectl krew install virt

kind create cluster

export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases | grep tag_name | grep -v -- '-rc' | sort -r | head -1 | awk -F': ' '{print $2}' | sed 's/,//' | xargs)
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml

kubectl wait deployment virt-operator --for=condition=available --timeout=600s -n kubevirt

export KUBEVIRT_CDI_VERSION=$(curl -sL -o /dev/null -w %{url_effective} https://github.com/kubevirt/containerized-data-importer/releases/latest | xargs basename)
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$KUBEVIRT_CDI_VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$KUBEVIRT_CDI_VERSION/cdi-cr.yaml

kubectl wait deployment cdi-operator --for=condition=available --timeout=600s -n cdi
