---
name: Develop in a container in a Docker host with Aider AI agent
description: The goal is to try the experimental ai agent integration with Aider AI agent
---

# ai agent template for a workspace in a container on a Docker host

### Docker image

1. Based on latest python slim image e.g., `python:3.13-slim`
1. Includes tmux (and screen) package to render Aider logs in Coder workspace UI

[Image on DockerHub](https://hub.docker.com/repository/docker/marktmilligan/python/general)
[Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/python/Dockerfile)

### Apps included

1. A web-based terminal
1. VS Code Web IDE
1. An Aider app to open the Aider AI agent

### AI agent

1. The AI agent is a [aider ai agent](https://aider.chat/)
1. The Coder module installs and configures aider ai
1. The admin adds the OpenRouter API key when uploading the template
1. The user chooses from a list of valid AI providers and models on OpenRouter
1. The user enters a prompt to tell the agent what to do
1. Coder's workspace UI is configured to show agent output
1. Open the Aider app to see logs

### Resources

[Aider Coder Terraform module](https://registry.coder.com/modules/coder/aider)

[Docker Terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)

[Coder Terraform provider](https://registry.terraform.io/providers/coder/coder/latest/docs)
