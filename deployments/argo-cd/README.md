# ArgoCD Install
This repo uses Kustomize to make changes to Helm charts from ArgoCD. This gives us the ability to make changes without having configuration shift issues.

## Development
- kubectl apply -k overlays/dev

## Testing
- kubectl apply -k overlays/qa

## Production
- kubectl apply -k overlays/production