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
  ide-dir = {
    "IntelliJ IDEA Ultimate" = "idea",
    "PyCharm Professional" = "pycharm",
    "GoLand" = "goland",
    "WebStorm" = "webstorm" 
  } 
  image = {
    "IntelliJ IDEA Ultimate" = "marktmilligan/intellij-idea-ultimate:2022.3.2",
    "PyCharm Professional" = "marktmilligan/pycharm-pro:2022.3.2",
    "GoLand" = "marktmilligan/goland:2022.3.2",
    "WebStorm" = "marktmilligan/webstorm:2022.3.2"
  }  
}

variable "ide" {
  description = "JetBrains IDE"
  default     = "IntelliJ IDEA Ultimate"
  validation {
    condition = contains([
      "IntelliJ IDEA Ultimate",
      "PyCharm Professional",
      "GoLand",
      "WebStorm"
    ], var.ide)
    error_message = "Invalid JetBrains IDE!"   
}
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
  os   = "linux"
  arch = "amd64"
  dir = "/home/coder"
  startup_script = <<EOT
#!/bin/bash

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri}

# script to symlink JetBrains Gateway IDE directory to image-installed IDE directory
# More info: https://www.jetbrains.com/help/idea/remote-development-troubleshooting.html#setup
cd /opt/${lookup(local.ide-dir, var.ide)}/bin
./remote-dev-server.sh registerBackendLocationForGateway

  EOT  
}

resource "docker_container" "workspace" {
  count     = data.coder_workspace.me.start_count
  image     = "docker.io/${lookup(local.image, var.ide)}"
  # Uses lower() to avoid Docker restriction on container names.
  name      = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  hostname  = lower(data.coder_workspace.me.name)
  dns       = ["1.1.1.1"]

 entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]

  env        = ["CODER_AGENT_TOKEN=${coder_agent.dev.token}"]
  volumes {
    container_path = "/home/coder/"
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
    value = "docker.io/${lookup(local.image, var.ide)}"
  }  
}
