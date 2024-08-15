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

}

data "coder_workspace" "me" {
}

data  "coder_workspace_owner" "me" {

}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 1
}

resource "coder_agent" "dev" {
  os                      = "linux"
  arch                    = "amd64"


  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  display_apps {
    vscode = true
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = false
    web_terminal = true
  }

  startup_script_behavior = "non-blocking"

  dir = "/home/${local.user}"
  startup_script = <<EOT

#!/bin/sh

# start Kasm
/dockerstartup/kasm_default_profile.sh
/dockerstartup/vnc_startup.sh > /dev/null 2>&1 &

# use coder CLI to clone and install dotfiles
if [ ! -z "${data.coder_parameter.dotfiles_url.value}" ]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value} &
fi

# change shell
sudo chsh -s $(which bash) $(whoami)

# start Insomnia
# > /dev/null 2>&1
# Not recommending --no-sandbox; just using for testing
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
    url       = "http://localhost:6901/healthz/"
    interval  = 3
    threshold = 10
  } 
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = local.image
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
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
  name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.workspace[0].id   
  item {
    key   = "image"
    value = local.image
  }     
}
