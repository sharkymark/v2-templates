---
name: Develop in a container with VNC in a Kubernetes pod
description: The goal is to enable VNC in a container to access thick client apps that are not natively browser-enabled
tags: [cloud, kubernetes]
---

# VNC template for a workspace in a Kubernetes pod

### Apps included

1. A web-based terminal
1. VNC client and server

### Additional bash scripting

1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Clone repo

### Important Notes

1. Update the Kubernetes cluster namespace in the locals part of the template before creating the template or the workspace build will fail

### Intended use

1. Use VS Code Desktop to code - with uses Coder's VS Code extension and CLI from a local machine

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources

[VNC Dockerfile](https://github.com/coder/enterprise-images/tree/main/images/vnc)

[noVNC](https://novnc.com/info.html)

[TigerVNC](https://tigervnc.org/)
