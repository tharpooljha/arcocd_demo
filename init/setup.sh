#!/bin/sh
# Update argocd-cm definition by adding an entry for a new plugin and call it customized-helm.
kubectl apply -f manifests/argocd-cm.yml