terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
}

locals {
  image = "marktmilligan/kasm:latest"
}

provider "docker" {

}

provider "coder" {
}

data "coder_workspace" "me" {
}

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)

  see https://dotfiles.github.io
  EOF
  default = "git@github.com:sharkymark/dotfiles.git"
}

resource "coder_agent" "dev" {
  os                      = "linux"
  arch                    = "amd64"
  dir                     = "/home/kasm-user"
  startup_script = <<EOT

#!/bin/bash

set -e

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri} &

# start Kasm
/dockerstartup/kasm_default_profile.sh
/dockerstartup/vnc_startup.sh &

sleep 10 

# start Insomnia
insomnia &

  EOT  
}

resource "coder_app" "kasm" {
  agent_id      = coder_agent.dev.id
  slug          = "kasm"  
  display_name  = "Insomnia in KasmVNC"
  icon          = "https://avatars.githubusercontent.com/u/44181855?s=280&v=4"
  url           = "http://localhost:6901"
  subdomain = true
  share     = "owner"

  healthcheck {
    url       = "http://localhost:6901/healthz"
    interval  = 20
    threshold = 5
  } 
}


resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = local.image
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]

 entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]

  env        = ["CODER_AGENT_TOKEN=${coder_agent.dev.token}"]
  volumes {
    container_path = "/home/kasm-user/"
    volume_name    = docker_volume.coder_volume.name
    read_only      = false
  }  
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
}

resource "docker_volume" "coder_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.workspace[0].id   
  item {
    key   = "image"
    value = local.image
  }     
}
