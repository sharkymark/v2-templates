---
name: Develop with Go and VS Code in a Kubernetes pod
description: The goal is to enable Go container that VS Code Web and Desktop can connect to 
tags: [cloud, kubernetes]
---

# Go template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server (VS Code Web)

### Go image
1. [Go versions](https://go.dev/dl/) [Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/go/Dockerfile)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
2. Clone coder/coder OSS [repo](https://github.com/coder/coder)
3. Configure pod spec to use the Docker image specific to the IDE
4. Download and install the latest code-server (VS Code Web) on each workspace build

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to enter a valid workspaces_namespace at workspace creation to point to the Kubernetes namespace the workspace will be deployed to

### Resources
[Go release history](https://go.dev/doc/devel/release)

[coder/coder repo](https://github.com/coder/coder)