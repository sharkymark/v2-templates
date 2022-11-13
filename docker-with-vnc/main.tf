terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.0"
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

resource "coder_agent" "dev" {
  arch           = "amd64"
  os             = "linux"
  startup_script  = <<EOT
#!/bin/bash

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 &

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri}

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
  slug          = "code-server"  
  display_name  = "VS Code"
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

resource "coder_app" "novnc" {
  agent_id      = coder_agent.dev.id
  slug          = "vnc"  
  display_name  = "NoVNC Desktop"
  icon          = "/icon/novnc.svg"
  url           = "http://localhost:6081"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:6081/healthz"
    interval  = 5
    threshold = 15
  } 
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
