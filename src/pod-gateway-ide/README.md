---
name: Develop with JetBrains Gateway in a Kubernetes pod
description: The goal is to enable a container that JetBrains Gateway can connect to 
tags: [cloud, kubernetes]
---

# JetBrains Gateway template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. JetBrains IDE (accessible with SSH and JetBrains Gateway)

### JetBrains IDE images to choose from
1. [IntelliJ IDEA Ultimate](https://www.jetbrains.com/idea/download/) [Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/intellij-idea/ultimate/Dockerfile)
1. [PyCharm Professional](https://www.jetbrains.com/pycharm/download/) [Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/pycharm/pycharm-pro/Dockerfile) 
1. [GoLand](https://www.jetbrains.com/goland/download/) [Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/goland/Dockerfile)
1. [WebStorm](https://www.jetbrains.com/webstorm/download/) [Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/webstorm/Dockerfile)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for JetBrains IDE
1. Configure pod spec to use the Docker image specific to the IDE
1. [Run JetBrains script](https://www.jetbrains.com/help/idea/remote-development-troubleshooting.html#setup) to direct Gateway IDE path to the JetBrains directory in the image

### Post Build Requisites
1. Install and configure [JetBrains Gateway](https://coder.com/docs/v2/latest/ides/gateway)

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to enter a valid workspaces_namespace at workspace creation to point to the Kubernetes namespace the workspace will be deployed to

### Resources
[JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/)

[Code Gateway docs](https://coder.com/docs/v2/latest/ides/gateway)

[Gateway docs](https://www.jetbrains.com/help/idea/remote-development-a.html#gateway)

[Gateway Issue Tracker](https://youtrack.jetbrains.com/issues/CWM?_ga=2.95348572.1706460293.1667768201-1827063151.1646598008&_gl=1*jrexxd*_ga*MTgyNzA2MzE1MS4xNjQ2NTk4MDA4*_ga_9J976DJZ68*MTY2NzkxMTA1Mi4xOC4xLjE2Njc5MTE1MDUuMC4wLjA.)