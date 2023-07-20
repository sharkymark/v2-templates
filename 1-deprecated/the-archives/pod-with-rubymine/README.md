---
name: Develop in a Ruby on Rails container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and JetBrains RubyMine
tags: [cloud, kubernetes]
---

# JetBrains IntelliJ template for Java development

### Compute
1. 4 CPU cores
1. 4 GB memory
1. 10 GB persistent volume claim storage

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. JetBrains RubyMine IDE (in-a-browser) Note: uses JetBrains OSS projector

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Show user the VS Code extension to use (XDebug for debugging)
1. Prompt user for folder to add to VS Code
1. Prompt user for which IntelliJ release to download and use
1. Prompt user for CPU, memory, and disk storage
1. Install [JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)
1. Use `projector ide autoinstall` to download and install RubyMine
1. Start the RubyMine IDE
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. JetBrains projector by default creates password tokens to pass in the IDE querystring. Coder OSS cannot load with that querystring. The temporary fix is to delete the token input parameter in `run.sh` in the config folder.

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[projector CLI commands](https://github.com/JetBrains/projector-installer/blob/master/COMMANDS.md)

[JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)