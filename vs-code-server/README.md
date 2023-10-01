---
name: Develop in a container in a Kubernetes pod with Microsoft Visual Studio Code Server
description: The goal is to enable Microsoft Visual Studio Code Server (VS Code in a browser) 
tags: [cloud, kubernetes]
---

# Microsoft Visual Studio Code Server template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. Microsoft Visual Studio Code Server IDE

### Additional input variables and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Clone source code repo
1. Download, install and start latest Microsoft Visual Studio Code Server

### Images/languages to choose from
1. NodeJS
1. Golang
1. Java
1. Base (for Rust and Python)

> Note that Rust is installed during the startup script for `~/` configuration
   
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

### Microsoft Visual Studio Code Server

> Microsoft has changed how to run Visual Studio Code Server remotely a couple times in 2023

1. Update the locals in the template for where you want the VS Code binary to be installed, the log path, and the port

```sh
${local.vscs_install_location}/code serve-web --port ${local.vscs_port} --without-connection-token --accept-server-license-terms --extensions-dir /home/coder/.vscode-server/extensions --log debug >${local.vscs_log_path} 2>&1 
```

2. Configure a `coder_app` block for the IDE

```hcl
# microsoft vs code server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  slug          = "code-server"  
  display_name  = "Visual Studio Code Server"
  icon          = "/icon/code.svg"
  url           = "http://localhost:13338?folder=/home/coder"
  subdomain = true
  share     = "owner"

  healthcheck {
    url       = "http://localhost:13338/healthz"
    interval  = 3
    threshold = 10
  }  
}
```

### Authentication

This template will use ~/.kube/config or if the control plane's service account token to authenticate to a Kubernetes cluster

Be sure to specify the workspaces_namespace variable during workspace creation to the Kubernetes namespace the workspace will be deployed to

### Resources
[Coder's Terraform Provider - parameters](https://registry.terraform.io/providers/coder/coder/latest/docs/data-sources/parameter)

[Microsoft VS Code Server home page](https://code.visualstudio.com/docs/remote/vscode-server)

[GitHub Copilot](https://github.com/features/copilot)

[GitHub Copilot Example Suggestions](https://docs.github.com/en/copilot/getting-started-with-github-copilot?tool=vscode)

[NodeJS coder-react repo](https://github.com/mark-theshark/coder-react)

[Coder's GoLang v2 repo](https://github.com/coder/coder)

[Coder's code-server TypeScript repo](https://github.com/coder/code-server)

[Golang command line repo](https://github.com/sharkymark/commissions)

[Java Hello World repo](https://github.com/sharkymark/java_helloworld)

[Rust repo](https://github.com/sharkymark/rust-hw)

[Python repo](https://github.com/sharkymark/python_commissions)

