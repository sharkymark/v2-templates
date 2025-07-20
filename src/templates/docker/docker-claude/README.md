---
name: Develop in a container in a Docker host with Anthropic Claude Code AI agent
description: The goal is to try the experimental ai agent integration with Claude CodeAI agent
---

# ai agent template for a workspace in a container on a Docker host

### Docker image

1. Based on latest python slim image e.g., `python:3.13-slim`

[Image on DockerHub](https://hub.docker.com/repository/docker/marktmilligan/python/general)
[Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/python/Dockerfile)

### Apps included

1. A web-based terminal
1. code-server Web IDE
1. A [sample app](https://github.com/gothinkster/realworld) to test the environment
1. [Claude Code AI agent](https://www.anthropic.com/claude-code) to assist with development tasks

### Resources

[Coder docs on AI agents and tasks](https://coder.com/docs/ai-coder/tasks)

[main.tf for Coder example](https://github.com/coder/registry/blob/main/registry/coder-labs/templates/tasks-docker/main.tf)

[Claude Code Coder Terraform module](https://registry.coder.com/modules/coder/claude-code)

[Docker Terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)

[Coder Terraform provider](https://registry.terraform.io/providers/coder/coder/latest/docs)
