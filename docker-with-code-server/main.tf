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

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

data "coder_workspace" "me" {
}

resource "coder_agent" "coder" {
  os   = "linux"
  arch = "amd64"
  dir = "/home/coder"
  startup_script = <<EOT
#!/bin/bash
export HOME=/home/coder

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 &

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  name          = "code-server"
  icon          = "https://cdn.icon-icons.com/icons2/2107/PNG/512/file_type_vscode_icon_130084.png"
  url           = "http://localhost:13337?folder=/home/coder"
  relative_path = true  
}


variable "docker_image" {
  description = "What docker image would you like to use for your workspace?"
  default     = "codercom/enterprise-base:ubuntu"
  validation {
    condition     = contains(["codercom/enterprise-base:ubuntu", "codercom/enterprise-node:ubuntu", "codercom/enterprise-java:ubuntu", "marktmilligan/phpstorm:latest", "marktmilligan/code-server:4.4.0-vs-code-1.66.2", "codercom/enterprise-intellij:ubuntu"], var.docker_image)
    error_message = "Invalid Docker Image!"
  }
}

resource "docker_volume" "coder_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-root"
}

resource "docker_container" "workspace" {
  count   = data.coder_workspace.me.start_count
  image   = var.docker_image
  name    = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-root"
  dns     = ["1.1.1.1"]
  command = ["sh", "-c", coder_agent.coder.init_script]
  env     = ["CODER_AGENT_TOKEN=${coder_agent.coder.token}"]
  volumes {
    container_path = "/home/coder/"
    volume_name    = docker_volume.coder_volume.name
    read_only      = false
  }
}