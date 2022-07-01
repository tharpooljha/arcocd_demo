# GitOps
Enterprise companies' operations must follow many regulatory requirements, data privacy regulations, and security standards. Security should follow the principle of least privilege access. Audits need to track who changed what and when on all production systems.

Organizations that use Kubernetes to run their application workloads have to follow these requirements when securing their clusters. Kubernetes isn't secure by default, but operators can use its features to make it secure.

GitOps is an operational framework for Kubernetes cluster management and application delivery. GitOps applies development practices like version control, collaboration, compliance, and continuous integration/continuous deployment (CI/CD) to infrastructure automation.

GitOps for Kubernetes places the cluster infrastructure desired state under version control. A component within the cluster continuously syncs the code. Rather than having direct access to the cluster, most operations happen through code changes that can be reviewed and audited. This approach supports the security principle of least privilege access.

This solution benefits any organization that wants the advantages of deploying applications and infrastructure as code, with an audit trail of every change.

TL;DR: GitOps solution provides a very easily understandable model - whatever is in Git is what Kubernetes has.

### Git Ops Principles
1. Declarative - A system managed by GitOps must have its desired state expressed declaratively.
2. Versioned and immutable - Desired state is stored in a way that enforces immuntability, versioning and retains a complete version history.
3. Pulled automatically - Software agents automatically pull the desired state declrations from source.
4. Continiously Reconciled - Software agents continiously observe actualy system state and attempt to apply the desired state.

### Benefits
Deploy faster and more often
Easier and quicker error handling and recovery
Self-documenting deployments
Elimination of configuration drift

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
5. Access admin UI https://52.153.251.182/ by getting password from kubectl secrets
`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo`
```
username: admin
```
6. Install argocd cli utility using install.sh
`./install.sh` or
```bash
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```
7. Login with ArgoCD CLI:
`argocd login localhost:8080`
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
- [Self Managed Argo](https://medium.com/devopsturkiye/self-managed-argo-cd-app-of-everything-a226eb100cf0)
- [GitOps Guide from OpenShift (Video)](https://www.youtube.com/watch?v=OIk53dRV8O8&list=PLaR6Rq6Z4IqfGCkI28cUMbNhPhsnj4nq3&index=2)
- [Open Git Ops](https://opengitops.dev)
- [ArgoCD Application Sets (Video)](https://www.youtube.com/watch?v=f27sfzUiaK4)
- [Manage More Clusters with Less Hassle (Video)](https://www.youtube.com/watch?v=GcvHKc2IHi8)
- [Live Demo of ArgoCD AppSets (Video)](https://www.youtube.com/watch?v=GcvHKc2IHi8)
- [Getting Started - Walkthrough of all the features](https://medium.com/@outlier.developer/getting-started-with-argocd-for-gitops-kubernetes-deployments-fafc2ad2af0)
- [ArgoCD - Github Apps of Apps Demo](https://github.com/kurtburak/argocd)
- [ArgoCD + Istio](https://github.com/argoproj/argo-cd/issues/2784)


**To Do:**
- [x] Create Directory Structure
- [ ] Use ArgoCD to manage ArgoCD
- [ ] Create Namespaces / Create labels
- [ ] Istio / Istio Gateway 
- [ ] Flagger
   - [ ] Install Flagger
   - [ ] Load Tester Install
- [ ] Hashi Corp Vault
- [ ] Prometheus (service monitor)
   - [ ] Virtual Services
- [ ] Grafana
   - [ ] Virtual Services
- [ ] Kiali
- [ ] Book Keeper
   - [ ] Virtual Services
- [ ] SSO + ArgoCD
- [ ] Tekton + ArgoCD Example

**Repo Directory Structure**
```
├── init
│   ├── install.sh
├── orchestration
│   ├── templates
│   │   ├── application-argo-cd.yaml
│   │   ├── application-template.yaml
│   │   ├── namespace-template.yaml
│   ├── Chart.yaml
│   ├── values-dev.yaml
│   ├── values-prod.yaml
│   ├── values.yaml
├── stack
│   ├── istio
│   │   ├── control-plane
│   │   ├── demo
│   │   ├── istioctl
│   │   ├── istio-operator.yaml
│   ├── prom
├── tools

```
$$ orchestration/values.yaml $$ 
```yaml
  # Service Mesh related
  - name: istio
    enabled: false
    namespace: istio-system
    loadPath: stack/service-mesh/istio
    ignoreDifferences:
      # Ignore caBundle diff due to runtime updates to the config
      - group: admissionregistration.k8s.io
        kind: MutatingWebhookConfiguration
        jsonPointers:
          - /webhooks/0/clientConfig/caBundle
          - /webhooks/0/failurePolicy
      - group: admissionregistration.k8s.io
        kind: ValidatingWebhookConfiguration
        jsonPointers:
          - /webhooks/0/clientConfig/caBundle
          - /webhooks/0/failurePolicy
  - name: networkservicemesh
    enabled: false
    loadPath: stack/service-mesh/networkservicemesh
```
$$ orchestration/templates/namespace-template.yaml $$ 
```
{{- range .Values.apps }}
{{- if and .enabled .namespace }}
---
apiVersion: v1
kind: Namespace
metadata:
  name: {{ .namespace }}
  {{- if (or .istioSidecar .istioRevision) }}
  labels:
    {{- if .istioRevision }}
    istio.io/rev: {{ .istioRevision }}
    {{- else if .istioSidecar }}
    istio-injection: enabled
    {{- end }}
  {{- end }}
...
{{- end }}
{{- end }}
```
Minimal `application.yaml`
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: guestbook
```


### ArgoCD apps of Apps pattern
The ArgoCD [apps of Apps ](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern) pattern is a way for ArgoCD to manage parent/child applications. It's purpose is to install many applications into the cluster using GitOps. It has the added benefit of cascading deletion. If you delete the parent application, the child resources, deployments will also be destroyed.

ArgoCD has a formal solution to replace the [app-of-apps](https://argoproj.github.io/argo-cd/operator-manual/cluster-bootstrapping/) pattern. You can learn more about the founding principles of the ApplicationSet controller from [the original design doc](https://docs.google.com/document/d/1juWGr20FQaJmuuTIS8mBFmWWDU422M_FQMuhp5c1jt4/edit?usp=sharing).

## ArgoCD Application Sets
[Documentation](https://argocd-applicationset.readthedocs.io/en/stable/)

The ApplicationSet controller is a [Kubernetes controller](https://kubernetes.io/docs/concepts/architecture/controller/) that adds support for an `ApplicationSet` [CustomResourceDefinition](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) (CRD).

###  ArgoCD Benefits
-   The ability to use a single Kubernetes manifest to target multiple Kubernetes clusters with Argo CD
-   The ability to use a single Kubernetes manifest to deploy multiple applications from one or multiple Git repositories with Argo CD
-   Improved support for monorepos: in the context of Argo CD, a monorepo is multiple Argo CD Application resources defined within a single Git repository
-   Within multitenant clusters, improves the ability of individual cluster tenants to deploy applications using Argo CD (without needing to involve privileged cluster administrators in enabling the destination clusters/namespaces)

# Application Set Generators
Generators are responsible for generating _parameters_, which are then rendered into the `template:` fields of the ApplicationSet resource. See the [Introduction](https://argocd-applicationset.readthedocs.io/en/stable/) for an example of how generators work with templates, to create Argo CD Applications.
-   [List generator](https://argocd-applicationset.readthedocs.io/en/stable/Generators-List/): The List generator allows you to target Argo CD Applications to clusters based on a fixed list of cluster name/URL values.
-   [Cluster generator](https://argocd-applicationset.readthedocs.io/en/stable/Generators-Cluster/): The Cluster generator allows you to target Argo CD Applications to clusters, based on the list of clusters defined within (and managed by) Argo CD (which includes automatically responding to cluster addition/removal events from Argo CD).
-   [Git generator](https://argocd-applicationset.readthedocs.io/en/stable/Generators-Git/): The Git generator allows you to create Applications based on files within a Git repository, or based on the directory structure of a Git repository.
-   [Matrix generator](https://argocd-applicationset.readthedocs.io/en/stable/Generators-Matrix/): The Matrix generator may be used to combine the generated parameters of two separate generators.
-   [Merge generator](https://argocd-applicationset.readthedocs.io/en/stable/Generators-Merge/): The Merge generator may be used to merge the generated parameters of two or more generators. Additional generators can override the values of the base generator.
-   [SCM Provider generator](https://argocd-applicationset.readthedocs.io/en/stable/Generators-SCM-Provider/): The SCM Provider generator uses the API of an SCM provider (eg GitHub) to automatically discover repositories within an organization.
-   [Pull Request generator](https://argocd-applicationset.readthedocs.io/en/stable/Generators-Pull-Request/): The Pull Request generator uses the API of an SCMaaS provider (eg GitHub) to automatically discover open pull requests within an repository.
- [Cluster Decision Resource generator](https://argocd-applicationset.readthedocs.io/en/stable/Generators-Cluster-Decision-Resource/): The Cluster Decision Resource generator is used to interface with Kubernetes custom resources that use custom resource-specific logic to decide which set of Argo CD clusters to deploy to.

## GitOps Advantages
- Separate repositories for each microservice deployment.
- Each repository has a Helm chart for the code.
- The helm charts are packaged and published to a registry.
- Application-level repos and helm charts allow for quickly collection microservices into an application.
- You can build a Helm Chart Template Library that allows for assembling Helm charts from re-usable template components.
- Deployment repositories also have pipelines and pipeline runs for external dependncies such as databases. 
- Use argo to sync pipelines, database schemas, etc... (Pipeline as code (tekton))
- Tekon reads from git repo and stores the pipeline runs.




# Kustomize
- Best suited for singular resources (not part of a collection)
- Modify pipeline runs existing in the deployment configuration repositories
- Modify files which require only small changes

### Results of Gitops
- The microservices can be reused quickly and efficiently, speeding up the creation of new web application.
- Configuration for external dependencies is deployed consistently.
- Developers can spin up new web applications without server admin intervention, including one-off instances to test functionallity.
- The process of promoting applications through the Development, QA, UAT, and Production stages is efficient and less prone to errors.
- Resource usage can be tracked at a higher rate of resolution
- Clusters themselves can be scaled up quickly

### Best practices
Seperate out deployment from service code
Create top level application repositories
Create top-level application helm charts
Clarify delineation of software for an application and software to multiple application
Health Checks for all microservices contribution towards an intelligent lifecycle
Mental Shift to provide software for consumption in other applications
Think/communicate in terms of git commit hashes
Improve documentation such as README and CHANGES files to better understand with the automation has

### Vault and Gitops
- Vault is actually a controller
- All dynamic secrets in Vault are required to have a lease
- A lease is required to force the connsumer to check in routinely. 
- You can't configure Vault declaratively. You can use Terraform for your configurations, or the [Vault Config Operator](https://github.com/joatmon08/vault-argocd/blob/main/secrets/database.yaml)

### Relevant Links
[What is vault?](https://www.vaultproject.io/docs/what-is-vault)
[Argo CD Vault Plugin](https://github.com/argoproj-labs/argocd-vault-plugin#argocd-vault-plugin)
[Injecting Vault Secrets into Kubernetes Pods via a Sidecar](https://www.hashicorp.com/blog/injecting-vault-secrets-into-kubernetes-pods-via-a-sidecar)
[Injecting Secrets into Kubernetes Pods via Vault Agent Containers](https://learn.hashicorp.com/tutorials/vault/kubernetes-sidecar?in=vault/kubernetes)
[Encrypting Files to Git Using SOPS - Walkthrough](https://blog.thenets.org/how-to-commit-encrypted-files-to-git-with-mozilla-sops/)
[Exploring HashiCorp Vault and ArgoCD the GitOps Way (PDF)](https://github.com/tracypholmes/all-things-advocacy/blob/main/vault-and-argocd-gitops/GitOpsCon%20EU%202022/GitOpsCon%20EU%202022%20-%20Exploring%20Vault%20and%20ArgoCD%20-%20The%20GitOps%20Way.pdf)


### Limits
- ApplicationSets are set to pull from github every 3 minutes. You can decrease this time by creating a new [webhook](https://argocd-applicationset.readthedocs.io/en/stable/Generators-Git/#webhook-configuration.
