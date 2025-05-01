---
name: Run a JetBrains IDE with JetBrains Gateway on your Docker workspace
description: The goal is to run a JetBrains IDE with JetBrains Gateway on your Docker workspace 
tags: [local, docker]
---

# Run a JetBrains IDE with JetBrains Gateway with container workspace on a Docker host

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Additional bash scripting
1. Prompt user for programming language
1. Configure pod spec to use the Docker image specific to the IDE
1. Clone repo specific to the programming language
1. Download, install and start code-server (VS Code-in-a-browser)

### Post Build Requisites
1. Download the Coder CLI to your local computer

    `curl -fsSL https://coder.com/install.sh | sh`

1. [Configure SSH](https://coder.com/docs/coder-oss/latest/ides#ssh-configuration) with Coder CLI (creates a host name to your Coder workspace)
1. Download JetBrains [Toolbox](https://www.jetbrains.com/toolbox-app/) and [Gateway](https://www.jetbrains.com/remote-development/gateway/) and make an SSH configuration to your Coder workspace
1. Connect to your Coder workspace with Gateway and start coding


### Authentication


### Resources
[Terraform Docker Provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)

[JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/)

[Gateway docs](https://www.jetbrains.com/help/idea/remote-development-a.html#gateway)

[Gateway Issue Tracker](https://youtrack.jetbrains.com/issues/CWM?_ga=2.95348572.1706460293.1667768201-1827063151.1646598008&_gl=1*jrexxd*_ga*MTgyNzA2MzE1MS4xNjQ2NTk4MDA4*_ga_9J976DJZ68*MTY2NzkxMTA1Mi4xOC4xLjE2Njc5MTE1MDUuMC4wLjA.)

