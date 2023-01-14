---
name: Develop in a Docker container on a Docker host and be able to use `docker build` and `docker run` and `docker compose`
description: The goal is to enable a Docker host within a a Docker container
tags: [cloud, kubernetes]
---

# Docker host template for a workspace in a Docker container

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Additional bash scripting
1. Start Docker daemon using a privileged side-car Docker container
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Clone coder/coder repo
1. Download, install and start code-server (VS Code-in-a-browser)

### Docker resource relevant snippet

> By removing a docker network, setting `network_mode = "host"` and setting the
> `DOCKER_HOST=localhost:2375`, running processes on any inner containers are
> accessible from `localhost` which enables port forwarding. The trade-off is
> network namespacing is disabled so a potential security risk.
> 
```sh
resource "docker_container" "dind" {
  image      = "docker:dind"
  privileged = true
  network_mode = "host"
  name       = "dind-${data.coder_workspace.me.id}"
  entrypoint = ["dockerd", "-H", "tcp://0.0.0.0:2375"]
}

resource "docker_container" "workspace" {
  count   = data.coder_workspace.me.start_count
  image   = "codercom/enterprise-golang:ubuntu"
  name    = "dev-${data.coder_workspace.me.id}"
  command = ["sh", "-c", coder_agent.coder.init_script]
  network_mode = "host"
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.coder.token}",
    "DOCKER_HOST=localhost:2375"
  ]
  volumes {
    container_path = "/home/coder/"
    volume_name    = docker_volume.coder_volume.name
    read_only      = false
  }    
}
```

### Resources

[Coder Docker in Docker docs](https://coder.com/docs/coder-oss/latest/templates/docker-in-docker)