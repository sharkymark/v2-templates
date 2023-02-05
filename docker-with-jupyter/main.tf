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

locals {
  jupyter-type-arg = "${var.jupyter == "notebook" ? "Notebook" : "Server"}"
}

variable "jupyter" {
  description = "Jupyter IDE type"
  default     = "notebook"
  validation {
    condition = contains([
      "notebook",
      "lab",
    ], var.jupyter)
    error_message = "Invalid Jupyter!"   
}
}

resource "coder_agent" "dev" {
  arch           = "amd64"
  os             = "linux"
  startup_script  = <<EOT
#!/bin/bash

# start jupyter 
jupyter ${var.jupyter} --${local.jupyter-type-arg}App.token='' --ip='*' &

# add some Python libraries
pip3 install --user pandas &

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri} &

# clone repo
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone --progress git@github.com:sharkymark/pandas_automl.git &

  EOT  
}

resource "coder_app" "jupyter" {
  agent_id      = coder_agent.dev.id
  slug          = "jupyter-${var.jupyter}"  
  display_name  = "jupyter-${var.jupyter}"
  icon          = "/icon/jupyter.svg"
  url           = "http://localhost:8888/"
  share         = "owner"
  subdomain     = true  

  healthcheck {
    url       = "http://localhost:8888/healthz"
    interval  = 10
    threshold = 20
  }  
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "codercom/enterprise-jupyter:ubuntu"
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1
  #entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]

  command = [
    "sh", "-c",
    <<EOT
    trap '[ $? -ne 0 ] && echo === Agent script exited with non-zero code. Sleeping infinitely to preserve logs... && sleep infinity' EXIT
    ${replace(coder_agent.dev.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}
    EOT
  ]

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
    value = "codercom/enterprise-jupyter:ubuntu"
  }
  item {
    key   = "repo cloned"
    value = "docker.io/sharkymark/pandas_automl.git"
  }  
  item {
    key   = "jupyter"
    value = "${var.jupyter}"
  }    
}
