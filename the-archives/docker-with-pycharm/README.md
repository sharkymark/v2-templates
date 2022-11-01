---
name: Develop in a Java container in a Docker
description: The goal is to enable code-server (VS Code) and JetBrains PyCharm
tags: [cloud, docker]
---

# JetBrains PyCharm template for Java development

### Compute
Default to availability on the Docker host 
(future enhancement to this template can include dynamic variables for `cpu_set` `cpu_shares` `memory` and `memory swap`)

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. JetBrains PyCharm IDE (in-a-browser) Note: uses JetBrains OSS projector

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Show user the VS Code extension to use
1. Prompt user for folder to add to VS Code
1. Prompt user for which PyCharm release to download and use
1. Prompt user for CPU, memory, and disk storage
1. Installing projector packages (you can alternatively put these into the image)
1. Install [JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)
1. Use `projector ide autoinstall` to download and install PyCharm
1. Start the PyCharm IDE
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. JetBrains projector by default creates password tokens to pass in the IDE querystring. Coder OSS cannot load with that querystring. The temporary fix is to delete the token input parameter in `run.sh` in the config folder.
1. Be sure the Coder OSS host has enough CPU, memory and storage (cached images quickly take up space)

### Authentication

A Docker engine must be on the Coder OSS host and running

### Resources
[projector CLI commands](https://github.com/JetBrains/projector-installer/blob/master/COMMANDS.md)

[JetBrains projector CLI](https://github.com/JetBrains/projector-installer#Installation)

[container resource in Terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container)

[volume resource in Terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/volume)