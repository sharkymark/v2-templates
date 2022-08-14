terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.4.4"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.20.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
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
  default = ""
}

variable "image" {
  description = <<-EOF
  Container images from coder-com

  EOF
  default = "codercom/enterprise-jupyter:ubuntu"
  validation {
    condition = contains([
      "codercom/enterprise-jupyter:ubuntu"
    ], var.image)
    error_message = "Invalid image!"   
}  
}

variable "repo" {
  description = <<-EOF
  Code repository to clone

  EOF
  default = "sharkymark/pandas_automl.git"
  validation {
    condition = contains([
      "sharkymark/pandas_automl.git"
    ], var.repo)
    error_message = "Invalid repo!"   
}  
}

variable "extension" {
  description = "VS Code extension"
  default     = "ms-toolsai.jupyter"
  validation {
    condition = contains([
      "ms-python.python",
      "ms-toolsai.jupyter"
    ], var.extension)
    error_message = "Invalid VS Code extension!"  
}
}

locals {
  code-server-releases = {
    "4.5.1 | Code 1.68.1" = "4.5.1"
    "4.4.0 | Code 1.66.2" = "4.4.0"
    "4.3.0 | Code 1.65.2" = "4.3.0"
    "4.2.0 | Code 1.64.2" = "4.2.0"
  }
  jupyter-type-arg = "${var.jupyter == "notebook" ? "Notebook" : "Server"}"
}

variable "code-server" {
  description = "code-server release"
  default     = "4.5.1 | Code 1.68.1"
  validation {
    condition = contains([
      "4.5.1 | Code 1.68.1",
      "4.4.0 | Code 1.66.2",
      "4.3.0 | Code 1.65.2",
      "4.2.0 | Code 1.64.2"
    ], var.code-server)
    error_message = "Invalid code-server!"   
}
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
jupyter ${var.jupyter} --no-browser --${local.jupyter-type-arg}App.token='' --ip='*' --${local.jupyter-type-arg}App.base_url=/@${data.coder_workspace.me.owner}/${lower(data.coder_workspace.me.name)}/apps/jupyter-${var.jupyter}/ &

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=${lookup(local.code-server-releases, var.code-server)}
code-server --auth none --port 13337 &

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri} 2>&1

# install pandas and numpy
pip3 install pandas numpy --user

# clone repo
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone git@github.com:${var.repo}

# install VS Code extension into code-server
SERVICE_URL=https://open-vsx.org/vscode/gallery ITEM_URL=https://open-vsx.org/vscode/item code-server --install-extension ${var.extension}

  EOT  
}

resource "coder_app" "code-server" {
  agent_id = coder_agent.dev.id
  name     = "code-server ${var.code-server}"
  url      = "http://localhost:13337/?folder=/home/coder"
  icon     = "/icon/code.svg"
}

resource "coder_app" "jupyter" {
  agent_id      = coder_agent.dev.id
  name          = "jupyter-${var.jupyter}"
  icon          = "/icon/jupyter.svg"
  url           = "http://localhost:8888/@${data.coder_workspace.me.owner}/${lower(data.coder_workspace.me.name)}/apps/jupyter-${var.jupyter}/"
  relative_path = true
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "${var.image}"
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1
  # entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]

  command = [
    "sh", "-c",
    <<EOT
    trap '[ $? -ne 0 ] && echo === Agent script exited with non-zero code. Sleeping infinitely to preserve logs... && sleep infinity' EXIT
    ${replace(coder_agent.dev.init_script, "localhost", "host.docker.internal")}
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
