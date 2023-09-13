---
name: Develop in a container in a Kubernetes pod
description: The goal is to have a container workspace to work on Coder bits 
tags: [cloud, kubernetes]
---

# code-server (VS Code) template for a workspace in a Kubernetes pod - for Coder bits

### Apps included
1. A web-based terminal
1. Coder's `code-server` project
1. Coder public Slack
1. Coder private Slack
1. Coder Discord community
1. GitHub Issues for Coder v2 repo

### Additional input variables and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone (Coder v2, code-server, envbuilder, logstream, envbox)
1. Clone source code repo
1. Download, install and start latest code-server (VS Code-in-a-browser)

### Images/languages to choose from
1. Golang
1. Base (includes Python)

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

Alternatively, the managed  terraform variables can be specified in the template UI

### Authentication

This template will use ~/.kube/config or if the control plane's service account token to authenticate to a Kubernetes cluster

Be sure to specify the workspaces_namespace variable during workspace creation to the Kubernetes namespace the workspace will be deployed to

### Resources
[Coder's Terraform Provider - parameters](https://registry.terraform.io/providers/coder/coder/latest/docs/data-sources/parameter)

[Coder's v2 repo](https://github.com/coder/coder)

[Coder's code-server repo](https://github.com/coder/code-server)

[Coder's Terraform Provider - coder_app for external links](https://registry.terraform.io/providers/coder/coder/latest/docs/resources/app)

[Coder envbuilder project (Kaniko devcontainer)](https://github.com/coder/envbuilder)

[Coder logstream-kube project](https://github.com/coder/coder-logstream-kube)

[Coder envbox project (sysbox runc)](https://github.com/coder/envbox)

