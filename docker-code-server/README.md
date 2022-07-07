---
name: Develop in a container in a Docker host with code-server
description: The goal is to enable code-server (VS Code) 
tags: [local, docker]
---

# code-server (VS Code) template for a workspace in a container on a Docker host

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for code-server release to install
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Prompt user for which VS Code extension to install from the Open VSX marketplace
1. Clone repo
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. Coder OSS currently does not have dev URL functionality built-in, so developers either use `coder port-forward <workspace name> --tcp 3000:3000` or `ssh -L 3000:localhost:3000 coder.<workspace name>`

### Authentication


### Resources
[coder-react repo](https://github.com/mark-theshark/coder-react)
[code-server releases](https://github.com/coder/code-server/releases)
