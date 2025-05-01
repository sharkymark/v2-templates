---
name: Develop with Postman in a container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and Postman and VNC
tags: [cloud, kubernetes]
---

# VNC and Postman and code-server (VS Code) template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. VNC
1. Postman

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. `pip3 install --user` some packages like `pandas` and `numpy`
1. Prompt user for compute options (CPU core, memory, and disk)
1. Start Postman (it is installed as part of the image)
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. Eclipse is in the image too but is not visible when VNC starts

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[Postman docs](https://www.postman.com/downloads/)
[XDOtool](https://manpages.ubuntu.com/manpages/xenial/man1/xdotool.1.html)
