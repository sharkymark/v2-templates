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
  image = "codercom/enterprise-desktop:latest"
}

data "coder_workspace" "me" {
}

data "coder_workspace_owner" "me" {
}

data "coder_provisioner" "me" {
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

provider "coder" {
}

module "kasmvnc" {
  count               = data.coder_workspace.me.start_count
  source              = "registry.coder.com/modules/kasmvnc/coder"
  version             = "1.0.23"
  agent_id            = coder_agent.dev.id
  desktop_environment = "xfce"
}

data "coder_parameter" "ide" {
  name        = "VS Code IDE"
  description = "Select a local or browser-based IDE"
  type        = "string"
  default     = "code"
  mutable     = true 
  icon        = "/icon/code.svg"
  order       = 1

  option {
    name = "VS Code Desktop"
    value = "code"
    icon = "/icon/code.svg"
  }
  option {
    name = "code-server (browser IDE)"
    value = "code-server"
    icon = "/icon/coder.svg"
  }


}

resource "coder_agent" "dev" {
  arch           = data.coder_provisioner.me.arch
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

  display_apps {
    vscode = data.coder_parameter.ide.value == "code"
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = true
    web_terminal = true
  }

  startup_script_behavior = "non-blocking"
  connection_timeout = 300  
  startup_script  = <<EOT
#!/bin/sh

# set -e

if [ "${data.coder_parameter.ide.value}" = "code-server" ]; then
  # start code-coder
  # Append "--version x.x.x" to install a specific version of code-server

    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server

    # Start code-server in the background.
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

fi

  EOT  
}

# coder technologies' code-server
resource "coder_app" "coder-code-server" {
  count = data.coder_parameter.ide.value == "code-server" ? 1 : 0
  agent_id = coder_agent.dev.id
  slug          = "coder"  
  display_name  = "code-server"
  url      = "http://localhost:13337"
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
  image = "${local.image}"
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
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
  name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.workspace[0].id   
  item {
    key   = "image"
    value = "${local.image}"
  }
}
