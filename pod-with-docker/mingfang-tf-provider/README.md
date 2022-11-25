---
name: Develop in a container in a Kubernetes pod and be able to use `docker build` and `docker run` and `docker compose`
description: The goal is to enable a Docker host within a Kubernetes pod
tags: [cloud, kubernetes]
---

# Docker host template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Additional bash scripting
1. Start Docker daemon using `sysbox` `runc` already running as a `systemd` service on the host
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Prompt user for the code-server (VS Code) release to use
1. Clone repo
1. Download, install and start code-server (VS Code-in-a-browser)

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[sysbox install package](https://github.com/nestybox/sysbox/blob/master/docs/user-guide/install-package.md)

[Coder Docker in Docker docs](https://coder.com/docs/coder-oss/latest/templates/docker-in-docker)