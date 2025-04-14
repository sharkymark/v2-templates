---
name: Develop in a container in a Docker host with Goose AI agent
description: The goal is to try the experimental ai agent integration with Goose AI agent
---

# ai agent template for a workspace in a container on a Docker host

### Docker image
1. Based on latest python slim image e.g., `python:3.13-slim`
1. Includes Node.sj and npm required to install Goose
1. Includes Screen package to render Goose logs in Coder workspace UI

### Apps included
1. A web-based terminal
1. choice of Coder code-server IDE, VS Code Desktop or Zed IDE (if either are installed locally)
1. A Goose app to open the Goose AI agent

### AI agent
1. The AI agent is a goose ai agent
1. The Coder module installs and configures goose ai
1. The user is prompted to enter an OpenRouter API key which Goose will use
1. The user enters a prompt to tell the agent what to do
1. There is a default prompt to build a simple guessing game in Python
1. Coder's workspace UI is configured to show agent output
1. Open the Goose app to see logs
1. Open web terminal or IDE terminal to run the generated app e.g., `python3 guessing_game.py`

### Resources

[Docker Terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
[Coder Terraform provider](https://registry.terraform.io/providers/coder/coder/latest/docs)