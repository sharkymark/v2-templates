---
name: Develop in a Rust container in a Kubernetes pod
description: The goal is to enable a Rust programming environment including code-server (VS Code) and JetBrains Projector CLion
tags: [cloud, kubernetes]
---

# JetBrains CLion template for Rust development

### Compute
1. 4 CPU cores
1. 4 GB memory
1. 10 GB persistent volume claim storage

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. JetBrains CLion IDE (in-a-browser) 
1. Image based on [this Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/clion/latest)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Install [JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)
1. Use `projector config add` to create a config folder for CLion
1. Start the CLion IDE
1. Download, install and start code-server (VS Code-in-a-browser)
1. Prompt user for which Rust VS Code extension to use
1. Prompt user for folder to add to VS Code (e.g., repo location with .toml file)

### Known limitations
1. JetBrains projector is no longer an actively maintained OSS project. Consider using [JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/)

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[projector CLI commands](https://github.com/JetBrains/projector-installer/blob/master/COMMANDS.md)

[JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)