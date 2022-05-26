#!/bin/sh
# Update argocd-cm definition by adding an entry for a new plugin and call it customized-helm.
kubectl create namespace argocd
#kubectl apply -f manifests/argocd-cm.yml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Pre argocd v2.30
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/applicationset/v0.4.1/manifests/install.yaml