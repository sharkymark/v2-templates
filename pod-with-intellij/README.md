---
name: Develop in a Java container with IntelliJ in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and JetBrains Projector IntelliJ
tags: [cloud, kubernetes]
---

# IntelliJ template

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. JetBrains IntelliJ IDE (in-a-browser) Note: uses JetBrains OSS projector
1. A 2nd IntelliJ IDE for developers who want to open two projects (more IDEs can be used if enough compute is on the workspace)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Install [JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)
1. Copy the image-installed IntelliJ IDE to the $HOME folder
1. Use `projector config add` to create a config folder without password tokens
1. Start the IntelliJ IDE
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. This approach depends on IntelliJ being installed in the image. An alternative is to use `projector ide autoinstall` to download and install the IDE, but `'projector config add` must also be run to overcome Coder OSS limitations with querystrings in the URI for the IDE in a browser.

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[projector CLI commands](https://github.com/JetBrains/projector-installer/blob/master/COMMANDS.md)

[JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)