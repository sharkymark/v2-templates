---
name: Run a JetBrains IDE with JetBrains Gateway on your Docker workspace
description: The goal is to run a JetBrains IDE with JetBrains Gateway on your Docker workspace 
tags: [local, docker]
---

# Run a JetBrains IDE with JetBrains Gateway with container workspace on a Docker host

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
1. Prompt user for JetBrains IDE
1. Configure `docker_container` resource to use the Docker image specific to the IDE
1. [Run JetBrains script](https://www.jetbrains.com/help/idea/remote-development-troubleshooting.html#setup) to direct Gateway IDE path to the JetBrains directory in the image

### Post Build Requisites
1. Install and configure [JetBrains Gateway](https://coder.com/docs/v2/latest/ides/gateway)



### Authentication


### Resources
[Terraform Docker Provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)

[JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/)

[Coder Gateway docs](https://coder.com/docs/v2/latest/ides/gateway)

[Gateway docs](https://www.jetbrains.com/help/idea/remote-development-a.html#gateway)

[Gateway Issue Tracker](https://youtrack.jetbrains.com/issues/CWM?_ga=2.95348572.1706460293.1667768201-1827063151.1646598008&_gl=1*jrexxd*_ga*MTgyNzA2MzE1MS4xNjQ2NTk4MDA4*_ga_9J976DJZ68*MTY2NzkxMTA1Mi4xOC4xLjE2Njc5MTE1MDUuMC4wLjA.)

