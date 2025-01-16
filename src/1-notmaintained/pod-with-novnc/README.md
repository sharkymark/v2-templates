---
name: Develop with VNC in container in a Kubernetes pod
description: The goal is to enable a VNC container for a browser experience
tags: [cloud, kubernetes]
---

# VNC template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. noVNC `coder_app` to open a XFce Linux Desktop

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Start TurboVNC server and noVNC web client

### Why this template?
1. Developers sometimes have utilities and IDEs that are not browser-based, so noVNC provides a web-based mechanism to access them
1. Child container images can inherit this image for use cases like JetBrains IDEA IntelliJ Community Edition 

### Package releases
1. TurboVNC `3.0.3`
1. VirtualGL `3.1`
1. libjpeg `3.0`
1. noVNC `1.4.0`
1. websockify `0.11.0`
1. XFce `4.18`

### VNC settings
1. Copy a custom `index.html` to `/opt/vnc` that auto-connects to noVNC without a `Connect` button
1. `VNC_RESOLUTION` set to `1280x1024` other options could be: `3840x2160` or `1920x1080`
1. `VNC_COL_DEPTH` set to `16` but default is `24`

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure an admin enters a valid workspaces_namespace in the locals section of the template to point to the Kubernetes namespace the workspace will be deployed to

### Resources
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