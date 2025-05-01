---
name: Develop in a container in a Kubernetes deployment with TabNine
description: The goal is to enable code-server and a Kubernetes deployment with TabNine
tags: [cloud, kubernetes]
---

# TabNine & code-server (VS Code) template for a workspace in a Kubernetes deployment

### Apps included
1. A web-based terminal
2. `code-server` IDE

### Additional input variables and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Clone source code repo
1. Download, install and start latest code-server (VS Code-in-a-browser)
1. Install TabNine VS Code extensions

### TabNine

[TabNine VS Code extension](https://marketplace.visualstudio.com/items?itemName=TabNine.tabnine-vscode)

[Model location](https://support.tabnine.com/hc/en-us/articles/5226305571089-Models-location)

[TabNine value proposition - your source code is not being sent somewhere](https://support.tabnine.com/hc/en-us/articles/4413853954321-Does-Tabnine-store-and-use-my-code-)


This template lets the user choose a Copilot chat VS Code extension release


### Images/languages to choose from
1. NodeJS
1. Golang
1. Java
1. Base (for Rust and Python)

> Note that Rust is installed during the startup script for `~/` configuration

### IDE use
1. While the purpose of this template is to show `code-server` and VS Code in a browser, you can also use the `VS Code Desktop` to download Coder's VS Code extension and the Coder CLI to remotely connect to your Coder workspace from your local installation of VS Code.
   
### Parameters
Parameters allow users who create workspaces to additional information required in the workspace build. This template will prompt the user for:
1. A Dotfiles repository for workspace personalization `data "coder_parameter" "dotfiles_url"`
2. The size of the persistent volume claim or `/home/coder` directory `data "coder_parameter" "pvc"`

### Managed Terraform variables
Managed Terraform variables can be freely managed by the template author to build templates. Workspace users are not able to modify template variables. This template has two managed Terraform variables:
1. `use_kubeconfig` which tells Coder which cluster and where to get the Kubernetes service account
2. `workspaces_namespace` which tells Coder which namespace to create the workspace pdo

Managed terraform variables are set in coder templates create & coder templates push.

`coder templates create --variable workspaces_namespace='my-namespace' --variable use_kubeconfig=true --default-ttl 2h -y`

`coder templates push --variable workspaces_namespace='my-namespace' --variable use_kubeconfig=true  -y`

Alternatively, the managed terraform variables can be specified in the template UI

### Authentication

This template will use ~/.kube/config or if the control plane's service account token to authenticate to a Kubernetes cluster

Be sure to specify the workspaces_namespace variable during workspace creation to the Kubernetes namespace the workspace will be deployed to

## Deployment role and rolebinding to coder service account

You will need a deployment resource and verbs to the apps api

### enable deployments in the Coder Helm values.yaml

```yaml
coder:
  serviceAccount:
    workspacePerms: true
    enableDeployments: true 
```

### OR add to the existing `coder-workspace-perms` role

```sh
kubectl patch role coder-workspace-perms -n coder --type='json' -p='[{"op": "add", "path": "/rules/0", "value":{ "apiGroups": ["apps"], "resources": ["deployments"], "verbs": ["create","delete","deletecollection","get","list","update","patch","watch"]}}]'
```

> You will need to add this after each upgrading of a Coder release, unless Coder adds this to the helm chart

### OR create a clusterrole and binding to the coder service account

```sh
kubectl create clusterrole deployer --verb=get,list,watch,create,delete,patch,update --resource=deployments.apps --namespace=coder
kubectl create clusterrolebinding deployer-srvacct-default-binding --clusterrole=deployer --namespace=coder --serviceaccount=coder:coder
```

## Kubernetes deployment log streaming to workspace UI

Because this template is a Kubernetes deployment, you can stream the deployment's Kubernetes logs to the workspace build logs in the UI to help in troubleshooting and verifying the creation of Kubernetes resources. You will also need to `helm install` Coder's `code-logstream-kube` in the same namespace. [Install steps here](https://github.com/coder/coder-logstream-kube)

Kubernetes provides an [informers Go API](https://pkg.go.dev/k8s.io/client-go/informers) that streams pod and event data from the API server.

coder-logstream-kube listens for pod creation events with containers that have the CODER_AGENT_TOKEN environment variable set. All pod events are streamed as logs to the Coder API using the agent token for authentication.

### Resources
[Coder's Terraform Provider - parameters](https://registry.terraform.io/providers/coder/coder/latest/docs/data-sources/parameter)

[Kubernetes deployment docs](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

[code-logstream-kube repo](https://github.com/coder/coder-logstream-kube)

[NodeJS coder-react repo](https://github.com/mark-theshark/coder-react)

[Coder's GoLang v2 repo](https://github.com/coder/coder)

[Coder's code-server TypeScript repo](https://github.com/coder/code-server)

[Golang command line repo](https://github.com/sharkymark/commissions)

[Java Hello World repo](https://github.com/sharkymark/java_helloworld)

[Rust repo](https://github.com/sharkymark/rust-hw)

[Python repo](https://github.com/sharkymark/python_commissions)

