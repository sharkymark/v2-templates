---
name: Develop in a container with IntelliJ & Gateway
description: The goal is to enable VNC and IntelliJ & Gateway
tags: [jetbrains, docker]
---

# IntelliJ  thru Gateway in a container

### Apps included
1. A web-based terminal
1. IntelliJ Ultimate IDE

### Under the hood

[JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/) is a thick client that interacts with a headless IntelliJ IDE running in a container.

The Coder Registry has a [Terraform Module](https://registry.coder.com/modules/jetbrains-gateway) to automatically download

1. the latest IntelliJ release into the container
2. the JetBrains client to run in the Gateway client on the local machine

### Resources
[Docker Terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)

[Java Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/java)

[JetBrains Module](https://registry.coder.com/modules/jetbrains-gateway)

[JetBrains Gateway](ttps://www.jetbrains.com/remote-development/gateway/)
