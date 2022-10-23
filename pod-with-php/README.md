---
name: Develop in a PHP container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and a PHP interpreter
tags: [cloud, kubernetes]
---

# VS Code template for PHP development

### Default Compute
1. 1 CPU cores
1. 2 GB memory
1. 10 GB persistent volume claim storage

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Included in the container image
1. PHP 7.4 interpreter
1. Latest code-server IDE
1. A sample debugger `launch.json` in `/payload`
1. The debugger config `xdebug.ini` in `/etc/php/7.4/mods-available/`
1. [Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/phpstorm/projector-chmod)

### Additional user inputs and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for CPU, memory, and disk storage
1. Install VS Code extensions from Open-VSX marketplace
1. Copy the xdebug.ini config to support PHP debugging
1. Start code-server (VS Code-in-a-browser)
1. Clone 2 PHP repos
1. Start both PHP apps on ports 1026 and 1027

### Known limitations
1. [JetBrains Projector OSS](https://lp.jetbrains.com/projector/) is no longer actively supported by JetBrains. Consider running `coder config-ssh` and installing [JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/)

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources