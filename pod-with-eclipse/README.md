---
name: Develop with VNC (and Eclipse) in a container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and VNC (Eclipse)
tags: [cloud, kubernetes]
---

# Eclipse IDE within VNC and code-server (VS Code) template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. noVNC and Tiger VNC
1. Eclipse 

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Start VNC
1. Start Eclipse
1. Download, install and start code-server (VS Code-in-a-browser)

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[Eclipse Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/eclipse/Dockerfile)
