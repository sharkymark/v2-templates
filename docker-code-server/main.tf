terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.5.3"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.22.0"
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
    "latest" = "" 
    "4.7.1 | Code 1.71.2" = "4.7.1"
    "4.6.1 | Code 1.70.2" = "4.6.1" 
  }
}


variable "code-server" {
  description = "code-server release"
  default     = "latest"
  validation {
    condition = contains([
      "latest",
      "4.7.1 | Code 1.71.2",
      "4.6.1 | Code 1.70.2"      
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
echo "CS_REL value: " ${var.code-server}

if [[ "${var.code-server}" != "latest" ]]; then
  CS_REL=" -s -- --version=${lookup(local.code-server-releases, var.code-server)}"
fi

curl -fsSL https://code-server.dev/install.sh | sh $CS_REL
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
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 15
  }  
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "${var.image}"
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]

  # Use the docker gateway if the access URL is 127.0.0.1
  #entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]

  # Use the docker gateway if the access URL is 127.0.0.1
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
