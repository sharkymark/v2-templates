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
curl -fsSL https://code-server.dev/install.sh | sh -s -- --version=${var.code-server} 2>&1 | tee code-server.log
code-server --auth none --port 13337 2>&1 | tee -a code-server.log &

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri} 2>&1 | tee dotfiles-clone.log 

# start VNC
echo "Creating desktop..."
mkdir -p "$XFCE_DEST_DIR"
cp -rT "$XFCE_BASE_DIR" "$XFCE_DEST_DIR"
# Skip default shell config prompt.
cp /etc/zsh/newuser.zshrc.recommended $HOME/.zshrc
echo "Initializing Supervisor..."
nohup supervisord

  EOT  
}

resource "coder_app" "code-server" {
  agent_id = coder_agent.dev.id
  url      = "http://localhost:13337/?folder=/home/coder"
  icon     = "/icon/code.svg"
}

resource "coder_app" "novnc" {
  agent_id      = coder_agent.dev.id
  name          = "noVNC Desktop"
  icon          = "/icon/novnc-icon.svg"
  url           = "http://localhost:6081"
  relative_path = true
}

resource "docker_image" "vnc" {
  name = "vnc:latest"
  build {
    path  = "./image/"
    #tag   = ["vnc:latest"]
  }
  #keep_locally = true
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.vnc.latest
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
