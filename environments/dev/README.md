# Readme.md
This will initiate core argoCD installation with `kubectl apply -k ./` to current used kubctl context 
(`kubectl config current-context`)

# Environment specific configuration
Besides the environment specific app installations and configurations, this directory contains additional resources an environment could need. Like for example the ArgoCD Project configuration and namespaces