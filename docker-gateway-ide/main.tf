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
  repo-owner = "marktmilligan"
  image = {
    "IntelliJ IDEA Ultimate" = "intellij-idea-ultimate:2023.1",
    "PyCharm Professional" = "pycharm-pro:2023.1",
    "GoLand" = "goland:2022.3.4",
    "WebStorm" = "webstorm:2023.1"
  }  
}

data "coder_provisioner" "me" {
}

provider "coder" {
  feature_use_managed_variables = "true"
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL"
  description = "Personalize your workspace"
  type        = "string"
  default     = "git@github.com:sharkymark/dotfiles.git"
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

data "coder_parameter" "ide" {

  name        = "JetBrains IDE"
  type        = "string"
  description = "What JetBrains IDE do you want?"
  mutable     = true
  default     = "IntelliJ IDEA Ultimate"
  icon        = "https://resources.jetbrains.com/storage/products/company/brand/logos/jb_beam.svg"

  option {
    name = "WebStorm"
    value = "WebStorm"
    icon = "/icon/webstorm.svg"
  }
  option {
    name = "GoLand"
    value = "GoLand"
    icon = "/icon/goland.svg"
  } 
  option {
    name = "PyCharm Professional"
    value = "PyCharm Professional"
    icon = "/icon/pycharm.svg"
  } 
  option {
    name = "IntelliJ IDEA Ultimate"
    value = "IntelliJ IDEA Ultimate"
    icon = "/icon/intellij.svg"
  }  

}


provider "docker" {

}

data "coder_workspace" "me" {
}

resource "coder_agent" "dev" {
  os                      = "linux"
  arch                    = data.coder_provisioner.me.arch
  #login_before_ready      = false
  dir                     = "/home/coder"
  env                     = { "DOTFILES_URI" = data.coder_parameter.dotfiles_url.value != "" ? data.coder_parameter.dotfiles_url.value : null }  
  startup_script          = <<EOT
#!/bin/bash

# use coder CLI to clone and install dotfiles
if [ -n "$DOTFILES_URI" ]; then
  echo "Installing dotfiles from $DOTFILES_URI"
  coder dotfiles -y "$DOTFILES_URI"
fi

# script to symlink JetBrains Gateway IDE directory to image-installed IDE directory
# More info: https://www.jetbrains.com/help/idea/remote-development-troubleshooting.html#setup
cd /opt/${lookup(local.ide-dir, data.coder_parameter.ide.value)}/bin
./remote-dev-server.sh registerBackendLocationForGateway

  EOT  
}

resource "docker_container" "workspace" {
  count     = data.coder_workspace.me.start_count
  image     = "docker.io/${local.repo-owner}/${lookup(local.image, data.coder_parameter.ide.value)}"
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
    value = "${lookup(local.image, data.coder_parameter.ide.value)}"
  }  
}
