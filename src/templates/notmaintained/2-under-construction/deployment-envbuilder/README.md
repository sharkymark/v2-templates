---
name: Allow developers to modify their environment in a tight feedback loop.
description: Build development environments from a Dockerfile on Kubernetes. Allow developers to modify their environment in a tight feedback loop.
tags: [cloud, kubernetes]
---

# `envbuilder` in a Kubernetes pod

A Development Container (or Dev Container for short) allows you to use a container as a full-featured development environment. A development container is a running Docker container with a well-defined tool/runtime stack and its prerequisites. It allows you to use a container as a full-featured development environment which can be used to run an application, to separate tools, libraries, or runtimes needed for working with a codebase, and to aid in continuous integration and testing.

Dev Containers are located in a `.devcontainer` directory at the root level of a code repository and contain a `devcontainer.json` which tells `envbuilder` and `Kaniko` how to access (or create) a development container with a well-defined tool and runtime stack.

[Kaniko](https://github.com/GoogleContainerTools/kaniko) is a tool to build container images from a Dockerfile, inside a container or Kubernetes cluster.

Kaniko doesn't depend on a Docker daemon and executes each command within a Dockerfile completely in userspace. This enables building container images in environments that can't easily or securely run a Docker daemon, such as a standard Kubernetes cluster.

`envbuilder` is an OSS project by Coder that uses Kaniko to build containers.

### Basic flow

1. Add code repositories with .devcontainer configs as `coder_parameter.devcontainer-repo` entries
1. On workspace creation, the workspace is built with Coder's `envbuilder` container image
1. The `entrypoint` starts the `envbuilder` binary which clones the devcontainer repo
1. Builds the image if a `Dockerfile` is in the devcontainer repo with [Kaniko](https://github.com/GoogleContainerTools/kaniko) or pulls the image
1. Starts the container from the devcontainer spec
1. Pulls and starts the `coder_agent` and runs `startup_script`

### Apps included

1. A web-based terminal
1. `code-server` - VS Code in a browser downloaded and started in `startup_script`

### Authentication

This template will use a service account to authenticate to a Kubernetes cluster

Be sure to enter a valid workspaces_namespace at template creation to point to the Kubernetes namespace the workspace will be deployed to

### Resources

[envbuilder repository](https://github.com/coder/envbuilder)

[Terraform provider for Kubernetes deployment](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment_v1)

[enbuilder starter devcontainer](https://github.com/coder/envbuilder-starter-devcontainer/blob/main/README.md)

[Microsoft's Development Container sample repo projects to use](https://github.com/microsoft/vscode-dev-containers)

[devcontainer metadata reference](https://containers.dev/implementors/json_reference/)

[Dev Containers explained (microsoft.com)](https://code.visualstudio.com/docs/devcontainers/containers)

[Coder Terraform Provider - Agent resource](https://registry.terraform.io/providers/coder/coder/latest/docs/resources/agent)
