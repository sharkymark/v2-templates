---
name: Develop in a container in a Kubernetes pod
description: The goal is to demonstrate parameters and Terraform managed variables 
tags: [cloud, kubernetes]
---

# code-server (VS Code) template for a workspace in a Kubernetes pod

### Parameters
Parameters allow users who create workspaces to additional information required in the workspace build. This template will prompt the user for:
1. A Dotfiles repository for workspace personalization `data "coder_parameter" "dotfiles_url"`
2. The size of the persistent volume claim or `/home/coder` directory `data "coder_parameter" "pvc"`

### Managed Terraform variables
Managed Terraform variables can be freely managed by the template author to build templates. Workspace users are not able to modify template variables. This template has two managed Terraform variables:
1. `use_kubeconfig` which tells Coder which cluster and where to get the Kubernetes service account
2. `workspaces_namespace` which tells Coder which namespace to create the workspace pdo

Managed terraform variables are set in coder templates create & coder templates push

`coder templates create --variable workspaces_namespace='my-namespace' --variable use_kubeconfig=true --default-ttl 2h -y`

`coder templates push --variable workspaces_namespace='my-namespace' --variable use_kubeconfig=true  -y`

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Additional input variables and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Download, install and start code-server (VS Code-in-a-browser)

### IDE use
1. While the purpose of this template is to show `code-server` and VS Code in a browser, you can also use the `VS Code Desktop` to download Coder's VS Code extension and the Coder CLI to remotely connect to your Coder workspace from your local installation of VS Code.

### Resources
[NodeJS coder-react repo](https://github.com/sharkymark/coder-react)

