---
name: Develop in a container with KasmVNC in a Kubernetes pod
description: The goal is to enable KasmVNC in a container to access thick client apps like Insomnia that are not natively browser-enabled
tags: [cloud, kubernetes]
---

# KasmVNC template with Insomnia API thick client app in a Kubernetes-managed pod and inner container

### Apps included

1. A web-based terminal
1. KasmVNC
1. Insomnia

[Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/kasm)

[DockerHub](https://hub.docker.com/repository/docker/marktmilligan/kasm/general)

### Additional bash scripting

1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Start KasmVNC
1. Start Insomnia

### Authentication

This template will use a service account to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable in the template creation to the Kubernetes namespace the workspace will be deployed to

### Resources

[Insomnia](https://insomnia.rest/)

[KasmVNC](https://www.kasmweb.com/)

[KasmVNC GitHub repo](https://github.com/kasmtech/KasmVNC)

[Credits: Ben Potter](https://github.com/bpmct/coder-templates/tree/main/better-vnc)
