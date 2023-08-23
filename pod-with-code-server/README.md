---
name: Develop in a container in a Kubernetes pod
description: The goal is to enable code-server (VS Code in a browser) 
tags: [cloud, kubernetes]
---

# code-server (VS Code) template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. VS Code IDE in a browwser (Coder's `code-server` project)

### Additional input variables and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Clone source code repo
1. Download, install and start latest code-server (VS Code-in-a-browser)
1. Download, install and start file-browser to show the contents of the `/home/coder` as a `coder_app` and web icon

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

Alternatively, the managed  terraform variables can be specified in the template UI

### Authentication

This template will use ~/.kube/config or if the control plane's service account token to authenticate to a Kubernetes cluster

Be sure to specify the workspaces_namespace variable during workspace creation to the Kubernetes namespace the workspace will be deployed to

### Resources
[Coder's Terraform Provider - parameters](https://registry.terraform.io/providers/coder/coder/latest/docs/data-sources/parameter)

[NodeJS coder-react repo](https://github.com/mark-theshark/coder-react)

[Coder's GoLang v2 repo](https://github.com/coder/coder)

[Coder's code-server TypeScript repo](https://github.com/coder/code-server)

[Golang command line repo](https://github.com/sharkymark/commissions)

[Java Hello World repo](https://github.com/sharkymark/java_helloworld)

[Rust repo](https://github.com/sharkymark/rust-hw)

[Python repo](https://github.com/sharkymark/python_commissions)

