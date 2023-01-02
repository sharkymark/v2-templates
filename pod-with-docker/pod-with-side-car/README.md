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
1. Start Docker daemon using a privileged side-car Docker container
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Clone coder/coder repo
1. Download, install and start code-server (VS Code-in-a-browser)

### pod spec relevant snippet

```sh
  spec { 
    security_context {
      fs_group    = "1000"
    }  
    # Run a privileged dind (Docker in Docker) container
    container {
      name  = "docker-sidecar"
      image = "docker:dind"
      security_context {
        privileged = true
      }
      command = ["dockerd", "-H", "tcp://127.0.0.1:2375"]
    }         
    container {
      name    = "go-container"
      image   = "docker.io/codercom/enterprise-golang:ubuntu"
      image_pull_policy = "Always"
      command = ["sh", "-c", coder_agent.coder.init_script]
      security_context {
        run_as_user = "1000"
      }      
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.coder.token
      }  
      # Use the Docker daemon in the "docker-sidecar" container
      env {
        name  = "DOCKER_HOST"
        value = "localhost:2375" 
      }
```

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources

[Kubernetes Terraform provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/pod)

[Coder Docker in Docker docs](https://coder.com/docs/coder-oss/latest/templates/docker-in-docker)