# Changelog
All notable changes to this project will be documented in this file.

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

### Fixed
- None
### Removed
- None