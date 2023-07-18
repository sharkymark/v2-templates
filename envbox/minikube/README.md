---
name: Run minikube in a Kubernetes pod
description: Run minikube inside an envbox container using the sysbox runc
tags: [cloud, kubernetes]
---

# minikube in a envbox-managed container inside a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server

### Template Admin inputs
1. namespace
1. K8s permissions method (.kube/config or control plane service account)
1. Envbox inputs (e.g., inner and outer container CPU, Memory, mounts)

### Developer inputs
1. Dotfiles repo

### Additional bash scripting
1. Install and start minikube
1. Start the minikube dashboard on port `42381` (accessible with `coder port-forward` on your local machine)
1. Create and expose a deployment and port forward outside the minikube cluster to open in a browser

```sh
coder port-forward <workspace name> --tcp 42381:42381
```

### Resources

[envbox docs](https://coder.com/docs/v2/latest/templates/docker-in-workspaces#envbox)

[envbox OSS project](https://github.com/coder/envbox)

[envbox starter template](https://github.com/coder/coder/tree/main/examples/templates/envbox)

[Nestybox (acquired by Docker, Inc.) - creators of sysbox container runtime](https://github.com/nestybox/sysbox/blob/master/docs/user-guide/security.md)

[minikube Getting Started](https://minikube.sigs.k8s.io/docs/start/)

[docker cli run commands](https://docs.docker.com/engine/reference/commandline/run/)