terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.4.2"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.16.0"
    }
  }
}

# compute parameters
variable "step1_docker_host_warning" {
  description = <<-EOF
  Is Docker running on the Coder host?

  This template will use the Docker socket present on
  the Coder host, which is not necessarily your local machine.

  You can specify a different host in the template file and
  surpress this warning.
  EOF
  validation {
    condition     = contains(["Continue using /var/run/docker.sock on the Coder host"], var.step1_docker_host_warning)
    error_message = "Cancelling template create."
  }
  sensitive = true
}

variable "step2_arch" {
  description = "arch: What architecture is your Docker host on?"
  validation {
    condition     = contains(["amd64", "arm64", "armv7"], var.step2_arch)
    error_message = "Value must be amd64, arm64, or armv7."
  }
  sensitive = true
}

variable "step3_OS" {
  description = <<-EOF
  What operating system is your Coder host on?
  EOF

  validation {
    condition     = contains(["macos", "windows", "linux"], var.step3_OS)
    error_message = "Value must be MacOS, Windows, or Linux."
  }
  sensitive = true
}

variable "dotfiles_uri" {
  description = <<-EOF
  Optional: enter dotfiles repo URI
  EOF

  default = "https://github.com/mark-theshark/dotfiles.git"
}

provider "docker" {
  host = var.step3_OS == "Windows" ? "npipe:////.//pipe//docker_engine" : "unix:///var/run/docker.sock"
}

provider "coder" {
}

data "coder_workspace" "me" {
}

resource "coder_agent" "dev" {
  arch = var.step2_arch
  os   = "linux"
#  dir            = "/home/${lower(data.coder_workspace.me.owner)}"
  startup_script = <<EOT
#!/bin/bash
set -euo pipefail

# clone dotfile repo
coder dotfiles -y ${var.dotfiles_uri}"

# set home folder
#export HOME=/home/${lower(data.coder_workspace.me.owner)}
export HOME=/home/coder

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337
  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.dev.id
  name          = "code-server"
  icon          = "https://cdn.icon-icons.com/icons2/2107/PNG/512/file_type_vscode_icon_130084.png"
  url           = "http://localhost:13337"
  relative_path = true  
}

variable "docker_image" {
  description = "What docker image would you like to use for your workspace?"
  default     = "codercom/enterprise-java:ubuntu"
  validation {
    condition     = contains(["codercom/enterprise-base:ubuntu", "codercom/enterprise-node:ubuntu", "codercom/enterprise-java:ubuntu", "marktmilligan/phpstorm:latest", "codercom/enterprise-jupyter","marktmilligan/pycharm-jupyter-python3:latest"], var.docker_image)
    error_message = "Invalid Docker Image!"
  }
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
}

resource "docker_container" "workspace" {
  count   = data.coder_workspace.me.start_count
  image   = var.docker_image
  name    = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  dns     = ["1.1.1.1"]
  command = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]
  env     = ["CODER_AGENT_TOKEN=${coder_agent.dev.token}"]
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }  
  volumes {
    container_path = "/home/coder/"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
}
