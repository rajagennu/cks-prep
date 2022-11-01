# Upgrade Kubernetes

- support
- security fixes
- bug fixes
- stay up to date for dependencies.

Sample version: 1.19.2 
1 : major
19: Minor : release every 3 months , no LTS Support.
2: patch

First upgrade the master components
  - apiserver, controller manager, scheduler
Then worker components
  - kubelet, kube-proxy

Components same minor version of apiserver or one version below works in the cluster. 

## Upgrade process
1. Kubectl drain to safely evict all pods from node, mark node as Scheduling Disabled (kubectl cordon).
2. Do the upgrade
3. kubectl uncordon

## Application availability during upgrade.
- Pod graceperiod / terminating state.
- Pod lifecycle events
- PodDisruptionBudget

## Upgrade control plane node
```bash
k drain cks-controlplane --ignore-daemonsets
apt-get update
apt-cache show kubeadm | grep 1.22
apt-mark hold kubelet kubectl
apt-mark unhold kubeadm
apt-get install kubeadm=1.22.5-00
kubeadm version
kubeadm upgrade plan
kubeadm upgrade apply v1.22.5

kubelet --version
kubectl --version
apt-mark unhold kubelet kubectl
apt-get install kubelet=1.22.5-00 kubectl=1.22.5-00

systemctl restart kubelet

kubeadm upgrade plan # shouldnt get anything to upgrade.
kubectl uncordon cks-controlplane
```
## Upgrade the node
```bash
k drain cks-node --ingore-daemonsets
# login into cks-node
apt-get update
apt-cache show kubeadm | grep 1.22
apt-mark hold kubelet kubectl 
apt-mark unmark kubeadm
apt-get install kubeadm=1.22.5-00
# for nodes
kubeadm upgrade node
apt-mark unhold kubelet kubectl
apt-mark hold kubeadm
apt-get install kubelet=1.22.5-00 kubectl=1.22.5-00
systemctl restart kubelet

# in controlplane
k get nodes # should observe the version number. 
k uncordon cks-node
```
