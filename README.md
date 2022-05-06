# GitOps
Enterprise companies' operations must follow many regulatory requirements, data privacy regulations, and security standards. Security should follow the principle of least privilege access. Audits need to track who changed what and when on all production systems.

Organizations that use Kubernetes to run their application workloads have to follow these requirements when securing their clusters. Kubernetes isn't secure by default, but operators can use its features to make it secure.

GitOps is an operational framework for Kubernetes cluster management and application delivery. GitOps applies development practices like version control, collaboration, compliance, and continuous integration/continuous deployment (CI/CD) to infrastructure automation.

GitOps for Kubernetes places the cluster infrastructure desired state under version control. A component within the cluster continuously syncs the code. Rather than having direct access to the cluster, most operations happen through code changes that can be reviewed and audited. This approach supports the security principle of least privilege access.

This solution benefits any organization that wants the advantages of deploying applications and infrastructure as code, with an audit trail of every change.

## Install ArgoCD
### Requirements
- Installed [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) command-line tool.
- Have a [kubeconfig](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) file (default location is ~/.kube/config).
### Getting Started
1. Install argocd namespace
`kubectl create namespace argocd`
2. Install ArgoCD using Helm
`kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
3. Wait for pods to come up
`sleep 30s`
`kubectl get pods -n argocd`
3. Configure External Access
    - Configure load balancer (unsafe because it exposes the cluster, dev only):
`kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'`
    - Port forward to your local machine:
`kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443`
    - Setup an [Ingress Controller](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/)
5. Access admin UI https://52.153.251.182/ by getting password from kubectl secerts
`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo`
```
                    Username: admin
                    Password: xxx
```
6. Install argocd cli utility using install.sh
`./install.sh` or
```bash
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```
7. Login with ArgoCD CLI:
`argocd login`
8. Change password:
`argocd account update-password`
(Optional: You should delete the argocd-initial-admin-secret from the Argo CD namespace once you changed the password. The secret serves no other purpose than to store the initially generated password in clear and can safely be deleted at any time. It will be re-created on demand by Argo CD if a new admin password must be re-generated.)

9. Setup argocd with external cluster: `kubectl config get-contexts -o name`
10. Set the context: `argocd cluster add ${clustername}`
10. Create Guestbook (demo) from CLI
`argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default`
9. Get status
`argocd app get guestbook`
10. Deploy (sync)
`argocd app sync guestbook`
```
azureuser@AZEISDEVMGMT2:~/argocd$ argocd app get guestbook
Name:               guestbook
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          default
URL:                https://52.153.251.182/applications/guestbook
Repo:               https://github.com/argoproj/argocd-example-apps.git
Target:             HEAD
Path:               guestbook
SyncWindow:         Sync Allowed
Sync Policy:        <none>
Sync Status:        Synced to HEAD (53e28ff)
Health Status:      Progressing

GROUP  KIND        NAMESPACE  NAME          STATUS  HEALTH       HOOK  MESSAGE
       Service     default    guestbook-ui  Synced  Healthy            service/guestbook-ui created
apps   Deployment  default    guestbook-ui  Synced  Progressing        deployment.apps/guestbook-ui created
```
You can test to see if the guestbook is deployed (Should return title): 
`kubectl exec "$(kubectl get pod -l app=helm-guestbook -o jsonpath='{.items[0].metadata.name}')" -c helm-guestbook -- curl -sS helm-guestbook | grep -o "<title>.*</title>"`

ArgoCD also supports uploading local manifests directly, but this is anti-pattern and should only be used for development. 
`argocd app sync APPNAME --local /path/to/dir/`

## Values Files
Helm has the ability to use differnt or multiple values.yaml files to derive parameters from. The flag can be repeated.

`argocd app set helm-guestbook --values values-production.yaml`

## Helm Release
By default, the Helm release name is equal to the Application name to which it belongs. Sometimes, especially on a centralised ArgoCD, you may want to override that name, and it is possible with the release-name flag on the cli:
`argocd app set helm-guestbook --release-name myRelease`


### More Research
- [**Open Policy Agent (OPA) Gatekeeper**](https://github.com/open-policy-agent/gatekeeper) - enforces policies with a validating admission webhook. Gatekeeper validates cluster configuration changes against provisioned policies, and applies the changes only if they comply with policies.
- [**Flux**](https://fluxcd.io/) Another GitOps operator that reconciles the cluster desired state in the Git repository with the deployed resources in the cluster.

### Resources Used
- [Digital Ocean](https://www.digitalocean.com/community/tutorials/how-to-deploy-to-kubernetes-using-argo-cd-and-gitops)
- [Integration Istio with DevOps](https://argoproj.github.io/argo-rollouts/features/traffic-management/istio/#integrating-with-gitops)
- [Argo Rollout Examples](https://github.com/argoproj/argo-rollouts/tree/master/examples)
- [Microsoft Gitops](https://docs.microsoft.com/en-us/azure/architecture/example-scenario/gitops-aks/gitops-blueprint-aks?WT.mc_id=containers-52942-jessde)