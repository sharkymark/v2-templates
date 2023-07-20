---
name: Develop in a container in a Kubernetes pod and be able to use pgAdmin to administer PostgreSQL databases
description: The goal is to enable pgAdmin to administer PostgreSQL databases
tags: [cloud, kubernetes]
---

# Docker host template for a workspace in a Kubernetes pod with pgAdmin

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. pgAdmin app 

### Additional bash scripting
1. Start Docker daemon using a privileged side-car Docker container
1. Prompt user for compute options (CPU core, memory, and disk)
1. Clone pgadmin docker compose repo
1. Start pgAdmin
1. Download, install and start code-server (VS Code-in-a-browser)

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources

[pgAdmin logo](https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Postgresql_elephant.svg/1200px-Postgresql_elephant.svg.png)

[Docker Compose](https://docs.docker.com/compose/compose-file/)

[Kubernetes Terraform provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)

[Coder Terraform provider](https://registry.terraform.io/providers/coder/coder/latest/docs)