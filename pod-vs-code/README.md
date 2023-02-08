---
name: Develop with local VS Code and NodeJS in a Kubernetes pod
description: The goal is to enable local VS Code to connect to a Coder workspace 
tags: [cloud, kubernetes]
---

# Local VS Code and NodeJS template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. NodeJS

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Clone NodejS React repo

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to enter a valid workspaces_namespace at workspace creation to point to the Kubernetes namespace the workspace will be deployed to

### Resources
[Coder VS Code Extension](https://marketplace.visualstudio.com/items?itemName=coder.coder-remote)

[Node React repo](https://github.com/sharkymark/coder-react)