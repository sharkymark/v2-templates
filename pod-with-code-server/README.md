---
name: Develop in a container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) 
tags: [cloud, kubernetes]
---

# code-server (VS Code) template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Additional input variables and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Prompt user for the code-server (VS Code) release to use
1. Clone repo
1. Download, install and start code-server (VS Code-in-a-browser)

### Images/languages to choose from
1. NodeJS
1. Golang
1. Java
1. Base (from Rust and Python)

> Note that Rust is installed during the startup script for `~/` configuration

### IDE use
1. While the purpose of this template is to show `code-server` and VS Code in a browser, you can also use the `VS Code Desktop` to download Coder's VS Code extension and the Coder CLI to remotely connect to your Coder workspace from your local installation of VS Code.
   
### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to specify the workspaces_namespace variable during workspace creation to the Kubernetes namespace the workspace will be deployed to

### Resources
[NodeJS coder-react repo](https://github.com/mark-theshark/coder-react)

[Coder's GoLang v2 repo](https://github.com/coder/coder)

[Coder's code-server TypeScript repo](https://github.com/coder/code-server)

[Golang command line repo](https://github.com/sharkymark/commissions)

[Java Hello World repo](https://github.com/sharkymark/java_helloworld)

[Rust repo](https://github.com/sharkymark/rust-hw)

[Python repo](https://github.com/sharkymark/python_commissions)

