---
name: Develop in a macOS container in a Docker host with VS Code Server
description: The goal is to enable a macOS container with a VS Code Server IDE
tags: [local, docker]
---

# code-server (VS Code) template for a workspace in a container on a Docker host

### Apps included
1. A web-based terminal
1. VS Code Server IDE

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Download, install and start VS Code Server (VS Code-in-a-browser)

### Extension Marketplaces
1. Microsoft's code-server installs GitHub Copilot from [Microsoft](https://marketplace.visualstudio.com/)

### Container image
1. `sickcodes/docker-osx:auto` is a very large image so the intial pull can take several minutes.

### Resources
[Matifali template with Microsoft VS Code Server](https://github.com/matifali/coder-templates/tree/main/deeplearning)

[Docker Terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)

[Container Image repo](https://github.com/sickcodes/Docker-OSX)