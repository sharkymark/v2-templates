---
name: Develop in a dev container in a Docker host
description: The goal is to enable a dev container in a Docker host
tags: [local, docker]
---

# dev container on a Docker host

### Apps included

1. A web-based terminal
1. VS Code Web IDE
1. VS Code Desktop (if installed locally)

### Additional scripting

1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for dev conainer repository to clone

### dev container support

This template uses the dev container CLI to manage the dev container lifecycle. This is new as of 2025-06-05 and is an alternative to Coder's envbuilder approach with Kaniko.

### Resources

[Docker Terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
