---
name: Develop in a Ruby on Rails container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and Ruby, and Ruby on Rails
tags: [cloud, kubernetes]
---

# VS Code template for PHP development

### Default Compute
1. 2 CPU cores
1. 2 GB memory
1. 10 GB persistent volume claim storage

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Included in the container image
1. Ruby 2.6.6, 2.7.2
1. bundler gem
1. Ruby on Rails
1. Latest code-server IDE
1. [Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/rbenv/rubymine)

### Additional user inputs and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for CPU, memory, and disk storage
1. Install VS Code Ruby debugger extension from Open-VSX marketplace
1. Start code-server (VS Code-in-a-browser)
1. Clone 3 Ruby on Rails repos (2 are private)
1. Start 3 apps on ports 3000, 3001, 3002

### Known limitations
1. [JetBrains Projector OSS](https://lp.jetbrains.com/projector/) is no longer actively supported by JetBrains. Consider running `coder config-ssh` and installing [JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/)

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources