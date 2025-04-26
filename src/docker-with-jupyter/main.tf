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
  cpu-limit = "1"
  memory-limit = "2G"
  cpu-request = "500m"
  memory-request = "500Mi" 
  home-volume = "10Gi"
  image = "marktmilligan/jupyter:latest"
  repo = "docker.io/sharkymark/pandas_automl.git"
}

variable "socket" {
  type        = string
  description = <<-EOF
  The Unix socket that the Docker daemon listens on and how containers
  communicate with the Docker daemon.

  Either Unix or TCP
  e.g., unix:///var/run/docker.sock

  EOF
  default = "unix:///var/run/docker.sock"
}

provider "docker" {
  host = var.socket
}

data "coder_workspace" "me" {
}

data "coder_workspace_owner" "me" {
}

provider "coder" {

}

module "dotfiles" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/dotfiles/coder"
  agent_id = coder_agent.dev.id
}

module "vscode-web" {
  count          = data.coder_workspace.me.start_count
  source         = "registry.coder.com/modules/vscode-web/coder"
  agent_id       = coder_agent.dev.id
  extensions     = ["github.copilot", "ms-python.python", "ms-toolsai.jupyter"]
  folder         = "/home/coder"
  accept_license = true
}

module "git-clone" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = "1.0.18"
  agent_id = coder_agent.dev.id
  url      = "https://github.com/sharkymark/pandas_automl"
}

resource "coder_agent" "dev" {
  arch           = "amd64"
  os             = "linux"

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "wush private key"
    key          = "4_wush_key"
    script       = <<EOT
    if [[ -f /tmp/wush.log ]]; then
      awk 'NR==2 {print}' /tmp/wush.log
    else
      echo 'wush not started yet'
    fi
    EOT
    interval     = 10
    timeout      = 1
  }

  display_apps {
    vscode = true
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = false
    web_terminal = true
  }

  env = { 
    
    }
  startup_script_behavior = "non-blocking"
  startup_script  = <<EOT
#!/bin/sh

set -e

# install wush for wireguard file transfer
# https://github.com/coder/wush
# install.sh installs incorrect version of wush
# curl -fsSL https://wush.dev/install.sh | sh

# get latest release from github
LATEST_RELEASE_URL=$(curl -fsSL \
  "https://api.github.com/repos/coder/wush/releases/latest" \
      | grep "browser_download_url" \
      | grep "linux_amd64.tar.gz" \
      | cut -d '"' -f 4 | head -n 1)

wget -qO- $LATEST_RELEASE_URL | tar -xz -C /tmp
sudo mv /tmp/wush /usr/local/bin

# start wush server
wush serve -v >/tmp/wush.log 2>&1 &

EOT
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "${local.image}"
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]

  env        = [
    "CODER_AGENT_TOKEN=${coder_agent.dev.token}"
  ]
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
  name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
}


resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.workspace[0].id   
  item {
    key   = "image"
    value = local.image
  }

}
