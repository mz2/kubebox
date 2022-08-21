#!/bin/bash

set -e pipefail

# Install krew

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

# Install virtctl as a krew plugin

kubectl krew install virt

# Create the cluster (this + below probably should be moved to a separate script, or conversely above could be part of cloud-config, just moving .krew to ubuntu user?)

kind create cluster --config cluster.yml

# Set up Kubevirt operator

export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases | grep tag_name | grep -v -- '-rc' | sort -r | head -1 | awk -F': ' '{print $2}' | sed 's/,//' | xargs)
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml

kubectl wait deployment virt-operator --for=condition=available --timeout=600s -n kubevirt

# Set up the Kubevirt CDI operator (image importer)

export KUBEVIRT_CDI_VERSION=$(curl -sL -o /dev/null -w %{url_effective} https://github.com/kubevirt/containerized-data-importer/releases/latest | xargs basename)
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$KUBEVIRT_CDI_VERSION/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/$KUBEVIRT_CDI_VERSION/cdi-cr.yaml

kubectl wait deployment cdi-operator --for=condition=available --timeout=600s -n cdi

# import the Jammy Server image

kubectl create -f pvc_jammy-server-amd64.yml
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/jammy-server-amd64

# hacky way of waiting for the importer to complete (since none of below appear to work)
kubectl logs pods/importer-jammy-server-amd64 --follow

# maybe should do instead like?
# kubectl wait --for=condition=PodCompleted --timeout -1s pod/importer-jammy-server-amd64

# ... or?
# kubectl wait --for=condition=Completed --timeout -1s pod/importer-jammy-server-amd64

# ... or?
# kubectl wait --for=condition=ContainersReady --timeout -1s pod/importer-jammy-server-amd64

# Create the VM
kubectl create -f vm_server22-amd64.yml
kubectl wait --for=condition=Ready virtualmachines/jammy-server-amd64-vm

# Create the load balancer Service to expose the ssh port externally
kubectl create -f vm-lb.yaml

# Alternative way to expose the ssh port
# kubectl virt expose vmi jammy-server-amd64-vm --name=jammy-server-amd64-ssh --port 22022 --target-port=22 --type=NodePort

# TODO: Wait for the load balancer to be available as well