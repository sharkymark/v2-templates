# Changelog

All notable changes to this project will be documented in this file.

## [Git credential parameters] - 2025-05-04

### Added

- Added Coder parameters for git credentials
- Impacted templates:
  - `docker-code-server`
  - `docker-ai-agent`
  - `docker-dev-container`

> Because I have a simple Coder deployment on my M3 MacBook, I cannot configure Coder to use an `CODER_EXTERNAL_AUTH_0_` with OAuth2. Therefore, I have the user enter their git credentials as `CODER_PARAMETER`s including a Personal Access Token (PAT) for GitHub. I also do not want to use the Coder-provided SSH key.

### Changed

- Resorted templates to `docker` and `kubernetes` folders

## [Kubernetes] - 2025-05-01

### Added

- 2 Kubernetes templates for `kubernetes-devcontainer` and `kubernetes`
- Used Coder modules for `coder login`, `dotfiles`
- No web IDEs, only VS Code Desktop

### Changed

- Resorted templates to `docker` and `kubernetes` folders

## [Transition to modules] - 2025-04-26

### Changed

- Updated all templates to use Coder modules
- e.g., coder login, VS Code Web, git clone, dotfiles
- Moved several Coder templates to `1-notmaintained` folder

## [Template update] - 2025-04-22

### Changed

- Updated the `docker-code-server` template to a new container image `marktmilligan/python-ai-agents:latest` which includes the Goose AI agent and Aider agent
- AI agent binaries are located in `/home/coder/.local/bin`
- DockerHub image is available at [https://hub.docker.com/repository/docker/marktmilligan/python-ai-agents](https://hub.docker.com/repository/docker/marktmilligan/python-ai-agents)
- Dockerfile is available at [https://github.com/sharkymark/dockerfiles/blob/main/python-code-gen/Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/python-code-gen/Dockerfile)

## [AI-related] - 2025-04-16

### Added

- created a new template `docker-ai-agent` to run a Goose AI agent in a container
- purpose is to test the UI integration with Coder workspace and Goose AI agent tasks
- uses a prompt `coder_parameter` for the user to enter a prompt
- uses an OpenRouter API key as a terraform variable for adding at template upload
- added a new [Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/python/Dockerfile) to build the image
- pushed the image to [DockerHub](https://hub.docker.com/repository/docker/marktmilligan/python/general)

### Changed

- Updated `docker-code-server` template with a `coder_app` to open the Zed IDE
- The user selects which IDE at workspace creation time e.g., `VS Code Desktop`, `code-server` or `zed`
