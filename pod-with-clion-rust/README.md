---
name: Develop in a Java container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and JetBrains Projector CLion
tags: [cloud, kubernetes]
---

# JetBrains CLion template for Rust development

### Compute
1. 4 CPU cores
1. 4 GB memory
1. 20 GB persistent volume claim storage

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. JetBrains CLion IDE (in-a-browser) Note: uses JetBrains OSS projector

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Install [JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)
1. Use `projector ide autoinstall` to download and install CLion
1. Use `projector config add` to create a config folder without password tokens
1. Start the CLion IDE
1. Download, install and start code-server (VS Code-in-a-browser)
1. Prompt user for which Rust VS Code extension to use
1. Prompt user for folder to add to VS Code (e.g., repo location with .toml file)

### Known limitations
1. JetBrains projector by default creates password tokens to pass in the IDE querystring. Coder OSS cannot load with that querystring. The temporary fix is to delete projector configs folder, and recreate it with the `projector config add` command which does not create password tokens.

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[projector CLI commands](https://github.com/JetBrains/projector-installer/blob/master/COMMANDS.md)

[JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)