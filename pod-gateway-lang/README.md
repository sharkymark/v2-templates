---
name: Develop with JetBrains Gateway in a Kubernetes pod
description: The goal is to enable a container that JetBrains Gateway can connect to 
tags: [cloud, kubernetes]
---

# JetBrains Gateway template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for programming language
1. Configure pod spec to use the Docker image specific to the IDE
1. Clone repo specific to the programming language
1. Download, install and start code-server (VS Code-in-a-browser)

### Post Build Requisites
1. If you will not be using the Coder Gateway plug-in, download the Coder CLI to your local computer

    `curl -fsSL https://coder.com/install.sh | sh`

1. If you will not be using the Coder Gateway plug-in, [Configure SSH](https://coder.com/docs/coder-oss/latest/ides#ssh-configuration) with Coder CLI (creates a host name to your Coder workspace)
1. Download JetBrains [Toolbox](https://www.jetbrains.com/toolbox-app/) and [Gateway](https://www.jetbrains.com/remote-development/gateway/)
1. Create an SSH connection in Gateway or install and use the [Coder Gateway plugin](https://plugins.jetbrains.com/plugin/19620-coder/)
1. Connect to your Coder workspace with Gateway and start coding

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to enter a valid workspaces_namespace at workspace creation to point to the Kubernetes namespace the workspace will be deployed to

### Resources

[Coder Gateway docs](https://coder.com/docs/v2/latest/ides/gateway)

[JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/)

[Gateway docs](https://www.jetbrains.com/help/idea/remote-development-a.html#gateway)

[Gateway Issue Tracker](https://youtrack.jetbrains.com/issues/CWM?_ga=2.95348572.1706460293.1667768201-1827063151.1646598008&_gl=1*jrexxd*_ga*MTgyNzA2MzE1MS4xNjQ2NTk4MDA4*_ga_9J976DJZ68*MTY2NzkxMTA1Mi4xOC4xLjE2Njc5MTE1MDUuMC4wLjA.)