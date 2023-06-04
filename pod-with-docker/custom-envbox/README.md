---
name: Run dockerd in a Kubernetes pod
description: Alternative to unprotected dockerd side-cars or sysbox on the host nodes
tags: [cloud, kubernetes]
---

# Kubernetes pod with a privileged container running dockerd and a user-defined inner container

### Apps included
1. A web-based terminal
1. code-server IDE

### Template Admin inputs
1. namespace
1. K8s permissions method (.kube/config or control plane service account)
1. Envbox inputs (e.g., mounts)

### Developer inputs
1. Container image e.g., Java, Node.js, Golang, Python, or a custom image and [Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/kitchen-sink/Dockerfile)
1. Dotfiles repo
1. CPU and memory limits
1. `/home/coder` storage size

### Resources

[envbox docs](https://coder.com/docs/v2/latest/templates/docker-in-workspaces#envbox)

[envbox OSS project](https://github.com/coder/envbox)

[envbox starter template](https://github.com/coder/coder/tree/main/examples/templates/envbox)

[Nestybox (acquired by Docker, Inc.) - creators of sysbox container runtime](https://github.com/nestybox/sysbox/blob/master/docs/user-guide/security.md)

[docker cli run commands](https://docs.docker.com/engine/reference/commandline/run/)