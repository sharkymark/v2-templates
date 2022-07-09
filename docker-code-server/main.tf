terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.4.2"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.17.0"
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
  default = "codercom/enterprise-node:ubuntu"
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
  default = "mark-theshark/coder-react.git"
  validation {
    condition = contains([
      "mark-theshark/coder-react.git",
      "mark-theshark/commissions.git",
      "mark-theshark/java_helloworld.git",
      "mark-theshark/python-commissions.git",
      "mark-theshark/pandas-automl.git",
      "mark-theshark/rust-hw.git"
    ], var.repo)
    error_message = "Invalid repo!"   
}  
}

variable "extension" {
  description = "Rust VS Code extension"
  default     = "matklad.rust-analyzer"
  validation {
    condition = contains([
      "rust-lang.rust",
      "matklad.rust-analyzer",
      "ms-python.python",
      "ms-toolsai.jupyter",
      "redhat.java",
      "golang.go"
    ], var.extension)
    error_message = "Invalid VS Code extension!"  
}
}

variable "code-server" {
  description = "code-server release"
  default     = "4.5.0"
  validation {
    condition = contains([
      "4.5.0",
      "4.4.0",
      "4.3.0",
      "4.2.0"
    ], var.code-server)
    error_message = "Invalid code-server!"   
}
}

resource "coder_agent" "dev" {
  arch           = "amd64"
  os             = "linux"
  startup_script  = <<EOT
#!/bin/bash

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=${var.code-server} 2>&1 > ~/code-server-install.log
code-server --auth none --port 13337 2>&1 > ~/code-server-start.log &

# clone repo
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
git clone --progress git@github.com:${var.repo} 2>&1 | tee repo-clone.log

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri} 2>&1 > ~/dotfiles.log

# install VS Code extension into code-server
SERVICE_URL=https://open-vsx.org/vscode/gallery ITEM_URL=https://open-vsx.org/vscode/item code-server --install-extension ${var.extension} | tee vscode-extension.log

  EOT  
}

resource "coder_app" "code-server" {
  agent_id = coder_agent.dev.id
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
