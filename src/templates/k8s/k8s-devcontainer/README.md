---
name: Develop in a dev container in a Kubernetes deployment
description: The goal is to enable a dev container in a Kubernetes deployment
tags: [kubernetes]
---

# VS Code Desktop template for a workspace in a dev container and Kubernetes deployment

### Apps included

1. A web-based terminal
1. VS Code Desktop (if installed locally)

### How it works

Coder has an image called envbuilder that is used to create a dev container by way of Google's [Kaniko](https://github.com/GoogleContainerTools/kaniko).

> Note: Dev container steps such postCreate and postStart will hang since logs are streamed to the Coder UI. Resolution is remove the postCreate and postStart steps from the devcontainer.json file.

### Additional scripting

> Coder registry modules are used for repeatability and maintainability

1. Prompt user and clone/install a dotfiles repository (for personalization settings)

### Resources

[Kuberenetes Terraform provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)

[Coder Terraform provider](https://registry.terraform.io/providers/coder/coder/latest/docs)

[Coder registry modules](https://registry.coder.com/modules)

[Coder envbuilder project](https://github.com/coder/envbuilder)

[Google Kaniko project](https://github.com/GoogleContainerTools/kaniko)
