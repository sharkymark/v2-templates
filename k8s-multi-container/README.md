---
name: Develop with 2 containers in a Kubernetes pod
description: The goal is to enable 2 containers, Postgres and Golang, in a K8s pod 
tags: [cloud, kubernetes]
---

# 2 containers in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server (VS Code Web)

### Images for the 2 containers
1. [Golang]()
1. [Postgres]()

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)

### Post Build Requisites
1. Clone the API repo
2. Build and start the Go binary
3. Make API calls in web terminal

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to enter a valid workspaces_namespace at workspace creation to point to the Kubernetes namespace the workspace will be deployed to

### Resources
[API example repo](https://github.com/gmhafiz/go8)

[Postgres image](https://hub.docker.com/_/postgres)

[Golang Dockerfile](https://github.com/coder/enterprise-images/tree/main/images/golang)

[Golang image](https://hub.docker.com/r/codercom/enterprise-golang)