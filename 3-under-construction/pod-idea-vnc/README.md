---
name: Develop with VNC & JetBrains IntelliJ IDEA Community in a Kubernetes pod
description: The goal is to enable an VNC & IntelliJ IDEA Community container for a browser experience
tags: [cloud, kubernetes]
---

# VNC & IntelliJ IDEA Community template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. JetBrains IDE (accessible with VNC)
1. noVNC `coder_app` to open a XFce Linux Desktop

### JetBrains IDE images to choose from
1. [IntelliJ IDEA Community](https://www.jetbrains.com/idea/download/) [Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/intellij-idea/vnc/Dockerfile)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Clone [iluwatar/java-design-patterns](https://github.com/iluwatar/java-design-patterns) repo
1. Start noVNC web client and TurboVNC server
1. Start IntelliJ IDEA Community

### Starting IntelliJ in VNC - delaying 10 seconds so VNC can fully load
``` sh
sleep 10
DISPLAY=:90 /opt/idea/bin/idea.sh &
```

### Known issues
1. The first time opening IntelliJ, a license screen appears off-screen in VNC. Widen the browser window and drag it to the top. Future restarts should be ok.

### Why this template?
1. Some users cannot pay for JetBrains licenses so want to use Community Editions

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure an admin enters a valid workspaces_namespace in the locals section of the template to point to the Kubernetes namespace the workspace will be deployed to

### Resources
