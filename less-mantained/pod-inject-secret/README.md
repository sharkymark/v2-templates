---
name: Pass a secret as an input parameter to a Kubernetes pod
description: The goal is to show how a secret can be entered into a Coder workspace 
tags: [cloud, kubernetes]
---

# Passing a secret into a developer workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. Node.JS image

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Echo the DEV_SECRET environment variable to show a user-entered secret is injected into a workspace

### How to view the secret
1. The `startup_script` echos the environment variable or open terminal and type `echo $DEV_SECRET`
1. A metadata element is surfaced in the workspace UI - click it see the secret 

### Warning

Any input parameter is stored in the Coder database as clear test. Also if an `owner` role has view access to a workspace, they can see the environment variables such as a secret.

### Authentication

This template will use a service account to authenticate to a Kubernetes cluster

Be sure to enter a valid workspaces_namespace at template creation to point to the Kubernetes namespace the workspace will be deployed to

### Resources
[Coder VS Code Extension](https://marketplace.visualstudio.com/items?itemName=coder.coder-remote)

[Node React repo](https://github.com/sharkymark/coder-react)

[Coder Youtube Video demoing the Coder Remote VS Code extension](https://youtu.be/OlFLZfGx8vw)

[Coder docs on parameters](https://coder.com/docs/v2/latest/templates/parameters)