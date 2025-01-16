---
name: Develop in a Java container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and JetBrains PhpStorm
tags: [cloud, kubernetes]
---

# JetBrains PhpStorm template for PHP development

### Default Compute
1. 4 CPU cores
1. 4 GB memory
1. 10 GB persistent volume claim storage

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. JetBrains PhpStorm IDE (in-a-browser) Note: uses JetBrains OSS projector

### Included in the container image
1. PHP 7.4 interpreter
1. Latest PhpStorm IDE
1. JetBrains Projector and related libraries to run IDE in a browser
1. Latest code-server IDE
1. A `configure` script to install VS Code extensions and copy Projector files to `$HOME`
1. [Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/phpstorm-vscode)

### Additional user inputs and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for CPU, memory, and disk storage
1. Install VS Code extensions from Open-VSX marketplace
1. Install [JetBrains Projector CLI](https://github.com/JetBrains/projector-installer#Installation)
1. Copy the xdebug.ini config to support PHP debugging
1. Use `projector config add` to configure Projector
1. Start the JetBrains PhpStorm IDE
1. Start code-server (VS Code-in-a-browser)

### Known limitations
1. [JetBrains Projector OSS](https://lp.jetbrains.com/projector/) is no longer actively supported by JetBrains. Consider running `coder config-ssh` and installing [JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/)

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[projector CLI commands](https://github.com/JetBrains/projector-installer/blob/master/COMMANDS.md)

[JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)