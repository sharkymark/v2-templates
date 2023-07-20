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
  user = "kasm-user"
}

variable "socket" {
  type        = string
  description = <<-EOF
  The Unix socket that the Docker daemon listens on and how containers
  communicate with the Docker daemon.

  Either Unix or TCP
  e.g., unix:///var/run/docker.sock

  EOF
  default = "unix:///var/run/docker.sock"
}

provider "docker" {
  host = var.socket
}

provider "coder" {
  feature_use_managed_variables = "true"
}

data "coder_workspace" "me" {
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL"
  description = "Personalize your workspace"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

resource "coder_agent" "dev" {
  os                      = "linux"
  arch                    = "amd64"
  dir                     = "/home/${local.user}"
  startup_script = <<EOT

#!/bin/sh

# start Insomnia
# Not recommending --no-sandbox; just using for testing
insomnia --no-sandbox > /dev/null 2>&1 &

# start Kasm
/dockerstartup/kasm_default_profile.sh
/dockerstartup/vnc_startup.sh > /dev/null 2>&1 &

# use coder CLI to clone and install dotfiles
if [ ! -z "${data.coder_parameter.dotfiles_url.value}" ]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value} &
fi

# change shell
sudo chsh -s $(which bash) $(whoami)

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
    url       = "http://localhost:6901/healthz/"
    interval  = 3
    threshold = 10
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
    container_path = "/home/${local.user}/"
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
