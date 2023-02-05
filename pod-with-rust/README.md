---
name: Develop with Rust in a container in a Kubernetes pod
description: The goal is to enable Rust development in a Kubernetes pod 
tags: [cloud, kubernetes]
---

# Rust template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. Rust programming language
1. There is no web IDE installed. Use `VS Code Desktop` to download the Coder VS Code extension and Coder CLI automatically to authenticate to the workspace.

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
2. Clone repo

### Notices
1. Rust needs configurations in `~` or `$HOME` so Rust is installed during the `coder_startup_script` and not the image. Therefore the first workspace build will be longer and Rust will be persisted in the mounted PVC. See `/Users/coder/.rustup`

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

During workspace creation, be sure to enter a valid workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to.

### Resources
[Ubuntu install guidance](https://www.digitalocean.com/community/tutorials/install-rust-on-ubuntu-linux)

[Rust source code repo](https://github.com/sharkymark/rust-hw)

[The official Rust book](https://doc.rust-lang.org)

[Coder VS Code extension on the Microsoft Extension Marketplace](https://marketplace.visualstudio.com/items?itemName=coder.coder-remote)