---
name: Develop in a container in a Kubernetes pod and be able to use `docker build` and `docker run` and `docker compose`
description: The goal is to enable a Docker host within a Kubernetes pod
tags: [cloud, kubernetes]
---

# Docker host template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Additional bash scripting
1. Start Docker daemon using `sysbox` `runc` already running as a `systemd` service on the host
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Prompt user for the code-server (VS Code) release to use
1. Clone repo
1. Download, install and start code-server (VS Code-in-a-browser)

### Requirements
1. The Kubernetes Terraform provider must be `2.16.0` or higher to support `runtime_class_name = "sysbox-runc"`

### pod spec relevant snippet

```sh
spec {
    # Use the Sysbox container runtime (required)
    runtime_class_name = "sysbox-runc"    
    security_context {
      run_as_user = "1000"
      fs_group    = "1000"
    }
    toleration {
      effect   = "NoSchedule"
      key      = "sysbox"
      operator = "Equal"
      value    = "oss"
    }
    node_selector = {
      "sysbox-install" = "yes"
    }        
    container {
      name    = "coder-container"
      image   = "docker.io/${var.image}"
      image_pull_policy = "Always"
      command = ["sh", "-c", coder_agent.coder.init_script]
      security_context {
        run_as_user = "1000"
      }      
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.coder.token
      }
```

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[sysbox install package](https://github.com/nestybox/sysbox/blob/master/docs/user-guide/install-package.md)

[Kubernetes Terraform provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/pod)

[Coder Docker in Docker docs](https://coder.com/docs/coder-oss/latest/templates/docker-in-docker)