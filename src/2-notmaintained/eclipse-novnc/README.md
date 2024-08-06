---
name: Develop with VNC (and Eclipse) in a container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and noVNC TurboVNC (Eclipse)
tags: [cloud, kubernetes]
---

# Eclipse IDE within noVNC client and TurboVNC server template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. noVNC and TurboVNC
1. Eclipse 

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Clone a sample Java repository
1. Prompt user for compute options (CPU core, memory, and disk)
1. Start VNC
1. Start Eclipse
1. Download, install and start code-server (VS Code-in-a-browser)

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[Eclipse Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/eclipse/novnc/Dockerfile)

[XFce4 Linux Desktop](https://www.xfce.org/)

[noVNC web client](https://novnc.com/info.html)

[noVNC releases](https://github.com/novnc/noVNC/releases)

[websocktify repo - convers websockets to sockets - part of noVNC solution](https://github.com/novnc/websockify)

[websocktify releases](https://github.com/novnc/websockify/releases)

[TurboVNC server](https://www.turbovnc.org/)

[TurboVNC releases](https://sourceforge.net/projects/turbovnc/files/)

[VirtualGL releases](https://sourceforge.net/projects/virtualgl/files/)

[libjpeg releases](https://sourceforge.net/projects/libjpeg-turbo/files/)

[codercom VNC Dockerfile - isn't using latest noVNC and TurboVNC](https://github.com/coder/enterprise-images/tree/main/images/vnc)
