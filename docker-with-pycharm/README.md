---
name: Develop in a Python container in a Docker
description: The goal is to enable code-server (VS Code) and JetBrains PyCharm in a Docker container
tags: [cloud, docker]
---

# JetBrains PyCharm template for Python development

### Compute
Default to availability on the Docker host 

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. JetBrains PyCharm IDE in the image Note: uses JetBrains projector

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Add the Microsoft Python VS Code extension
1. `chown` of the /opt dir to `coder` so projector CLI can create an PyCharm config
1. Install [JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)
1. Create the PyCharm config with projector CLI
1. Start the PyCharm IDE
1. Download, install and start code-server (VS Code-in-a-browser)
1. Clone 2 Python source code repos

### Known limitations
1. JetBrains' recommended remote solution is [Gateway](https://www.jetbrains.com/remote-development/gateway/). Consider switching to this using `coder config-ssh`
1. Be sure the Coder OSS host has enough CPU, memory and storage (cached images quickly take up space)

### Authentication

A Docker engine must be on the Coder OSS host and running

### Resources
[projector CLI commands](https://github.com/JetBrains/projector-installer/blob/master/COMMANDS.md)

[JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)

[Docker container resource in Terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container)

[Docker volume resource in Terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/volume)