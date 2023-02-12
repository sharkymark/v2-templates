---
name: Develop in a container with Kasm in a Kubernetes pod
description: The goal is to enable Kasm in a container to access thick client apps like Insomnia that are not natively browser-enabled
tags: [cloud, kubernetes]
---

# Kasm template with Insomnia API thick client app in a Kubernetes-managed pod and inner container

### Apps included

1. A web-based terminal
1. Kasm

### Additional bash scripting

1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Start Kasm
1. Starm Insomnia

### Authentication

This template will use a service account to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable in the template creation to the Kubernetes namespace the workspace will be deployed to

### Resources

[VNC Dockerfile](https://github.com/coder/enterprise-images/tree/main/images/vnc)

[Kasm](https://www.kasmweb.com/)

[Insomnia](https://insomnia.rest/)

[Credits: Ben Potter](https://github.com/bpmct/coder-templates/tree/main/better-vnc)
