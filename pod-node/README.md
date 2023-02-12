---
name: Develop with local VS Code and Node.JS and React in a Kubernetes pod
description: The goal is to enable local VS Code to connect to a Coder workspace 
tags: [cloud, kubernetes]
---

# Local VS Code and Node.JS & React template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. Node.JS and React

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Clone Node.jS React repo

### Authentication

This template will use a service account to authenticate to a Kubernetes cluster

Be sure to enter a valid workspaces_namespace at template creation to point to the Kubernetes namespace the workspace will be deployed to

### Resources
[Coder VS Code Extension](https://marketplace.visualstudio.com/items?itemName=coder.coder-remote)

[Node React repo](https://github.com/sharkymark/coder-react)

[Coder Youtube Video demoing the Coder Remote VS Code extension](https://youtu.be/OlFLZfGx8vw)