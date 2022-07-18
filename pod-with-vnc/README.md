---
name: Develop in a container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) 
tags: [cloud, kubernetes]
---

# VNC and code-server (VS Code) template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. Insomnia (accessible inside VNC)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Clone repo
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[coder-react repo](https://github.com/mark-theshark/coder-react)