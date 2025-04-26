---
name: Run a virtual desktop and Eclipse on your Docker workspace
description: The goal is to run a virtual desktop and Eclipse on your Docker workspace 
tags: [local, docker]
---

# Run a virtual desktop to container workspace on a Docker host

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. noVNC app to show Eclipse

### Additional bash scripting
1. Start VNC noVNC client and Tiger VNC server
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Download, install and start code-server (VS Code-in-a-browser)
1. Clone a Java repo
1. Start Eclipse and put in the VNC window

### Known limitations


### Authentication


### Resources
[Terraform Docker Provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)

[Image Resource](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image)

