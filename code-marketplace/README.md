---
name: Use code-server with a private VS Code extension marketplace
description: The goal is to use code-server with a private VS Code extension marketplace 
tags: [cloud, kubernetes, marketplace]
---

# code-server in a container pointing to a private VS Code extension marketplace

### Apps included
1. A web-based terminal
1. VS Code IDE in a browser (Coder's `code-server` project)

### Additional input variables and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Clone source code repo
1. Download, install and start latest code-server (VS Code-in-a-browser) pointing to a private VS Code extension marketplace

### Images/languages to choose from
1. NodeJS
1. Golang
1. Java
1. Base (for Rust and Python)

> Note that Rust is installed during the startup script for `~/` configuration

### Air-gap and security features enabled
1. Disable file downloads from `code-server` 
1. Point to an internal extensions marketplace

#### Disable file downloads

In the `startup_script` start `code-server` with the flag `code-server --auth none --port 13337 --disable-file-downloads`

### Internal VS Code Marketplace

Set an environment variable pointing to the new marketplace

```hcl

variable "marketplace" {
  description = <<-EOF
  VS Code extensions marketplace to connect the code-server IDE into

  EOF
  default = ""
}

resource "coder_agent" "coder" {
  os   = "linux"
  arch = "amd64"

...

  # specify an internal vs code extensions marketplace https://github.com/coder/code-marketplace#usage-in-code-server
  env = { "EXTENSIONS_GALLERY" = "{\"serviceUrl\":\"${var.marketplace}/api\", \"itemUrl\":\"${var.marketplace}/item\", \"resourceUrlTemplate\": \"${var.marketplace}/files/{publisher}/{name}/{version}/{path}\"}" }     
  startup_script = <<EOT

...
```
   
### Parameters
Parameters allow users who create workspaces to additional information required in the workspace build. This template will prompt the user for:
1. A Dotfiles repository for workspace personalization `data "coder_parameter" "dotfiles_url"`
2. The size of the persistent volume claim or `/home/coder` directory `data "coder_parameter" "pvc"`

### Terraform variables
Terraform variables can be freely managed by the template author to build templates. Workspace users are not able to modify template variables. This template has two Terraform variables:
1. `use_kubeconfig` which tells Coder which cluster and where to get the Kubernetes service account
2. `workspaces_namespace` which tells Coder which namespace to create the workspace pdo

Managed terraform variables are set in coder templates create & coder templates push.

`coder templates create --variable workspaces_namespace='my-namespace' --variable use_kubeconfig=true --default-ttl 2h -y`

`coder templates push --variable workspaces_namespace='my-namespace' --variable use_kubeconfig=true  -y`

Alternatively, the terraform variables can be specified in the template UI

### Authentication

This template will use ~/.kube/config or if the control plane's service account token to authenticate to a Kubernetes cluster

Be sure to specify the workspaces_namespace variable during workspace creation to the Kubernetes namespace the workspace will be deployed to

### VS Code extensions

1. The Coder Operator installs a private VS Code extension marketplace e.g., on a VM or with `helm` in Kubernetes
1. Manually download extensions as `vsix` files onto the marketplace server

`wget https://marketplace.visualstudio.com/_apis/public/gallery/publishers/GitHub/vsextensions/copilot/1.135.544/vspackage -O GitHub.copilot-1.135.544.vsix`

1. Run the `code-marketplace` to unzip and install the extension into the server's file structure

`/usr/bin/code-marketplace add GitHub.copilot-1.135.544.vsix --extensions-dir /home/coder/vsc-extensions`

### Resources

[code-marketplace repo](https://github.com/coder/code-marketplace)

[Coder's Terraform Provider - parameters](https://registry.terraform.io/providers/coder/coder/latest/docs/data-sources/parameter)

[NodeJS coder-react repo](https://github.com/mark-theshark/coder-react)

[Coder's GoLang v2 repo](https://github.com/coder/coder)

[Coder's code-server TypeScript repo](https://github.com/coder/code-server)

[Golang command line repo](https://github.com/sharkymark/commissions)

[Java Hello World repo](https://github.com/sharkymark/java_helloworld)

[Rust repo](https://github.com/sharkymark/rust-hw)

[Python repo](https://github.com/sharkymark/python_commissions)

