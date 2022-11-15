---
name: Develop Docker in Docker with in a container in a Docker host with code-server
description: The goal is to enable Docker in Docker
tags: [local, docker]
---

# Docker in Docker template for a workspace in a container on a Docker host

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Additional bash scripting
1. Start Docker daemon using `sysbox` `runc` already running as a `systemd` service on the host
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for code-server release to install
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Prompt user for which VS Code extension to install from the Open VSX marketplace
1. Clone repo
1. Download, install and start code-server (VS Code-in-a-browser)


### Resources
[sysbox install package](https://github.com/nestybox/sysbox/blob/master/docs/user-guide/install-package.md)

[Coder Docker in Docker docs](https://coder.com/docs/coder-oss/latest/templates/docker-in-docker)
