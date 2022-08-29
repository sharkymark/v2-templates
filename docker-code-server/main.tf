terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.4.9"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.20.2"
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
  default = "codercom/enterprise-golang:ubuntu"
  validation {
    condition = contains([
      "codercom/enterprise-node:ubuntu",
      "codercom/enterprise-golang:ubuntu",
      "codercom/enterprise-java:ubuntu",
      "codercom/enterprise-base:ubuntu",
      "marktmilligan/clion-rust:latest"
    ], var.image)
    error_message = "Invalid image!"   
}  
}

variable "repo" {
  description = <<-EOF
  Code repository to clone

  EOF
  default = "sharkymark/commissions.git"
  validation {
    condition = contains([
      "sharkymark/coder-react.git",
      "sharkymark/commissions.git", 
      "sharkymark/java_helloworld.git", 
      "sharkymark/python_commissions.git",                 
      "sharkymark/pandas_automl.git",
      "sharkymark/rust-hw.git"     
    ], var.repo)
    error_message = "Invalid repo!"   
}  
}

variable "extension" {
  description = "VS Code extension"
  default     = "golang.go"
  validation {
    condition = contains([
      "rust-lang.rust",
      "eg2.vscode-npm-script",
      "matklad.rust-analyzer",
      "ms-python.python",
      "ms-toolsai.jupyter",
      "redhat.java",
      "golang.go"
    ], var.extension)
    error_message = "Invalid VS Code extension!"  
}
}

locals {
  code-server-releases = {
    "4.6.0 | Code 1.70.1" = "4.6.0"    
    "4.5.1 | Code 1.68.1" = "4.5.1"
    "4.4.0 | Code 1.66.2" = "4.4.0"
    "4.3.0 | Code 1.65.2" = "4.3.0"
    "4.2.0 | Code 1.64.2" = "4.2.0"
  }
}

variable "code-server" {
  description = "code-server release"
  default     = "4.6.0 | Code 1.70.1"
  validation {
    condition = contains([
      "4.6.0 | Code 1.70.1",      
      "4.5.1 | Code 1.68.1",
      "4.4.0 | Code 1.66.2",
      "4.3.0 | Code 1.65.2",
      "4.2.0 | Code 1.64.2"
    ], var.code-server)
    error_message = "Invalid code-server!"   
}
}

resource "coder_agent" "dev" {
  arch           = "amd64"
  os             = "linux"
  startup_script  = <<EOT
#!/bin/bash

# clone repo
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone git@github.com:${var.repo}

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=${lookup(local.code-server-releases, var.code-server)}
code-server --auth none --port 13337 &

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri}

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

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "${var.image}"
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]

  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]

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
