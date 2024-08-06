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
  repo = "https://github.com/sharkymark/java_helloworld"
  repo-name = "java_helloworld" 
  image = "intellij-idea-community-vnc:latest"    
}



data "coder_workspace" "me" {
}

data "coder_workspace_owner" "me" {
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

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 4
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

  display_apps {
    vscode = true
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = false
    web_terminal = true
  }

  startup_script_behavior = "blocking"
  connection_timeout = 300  
  startup_script  = <<EOT
#!/bin/bash

# start VNC
# based on custom container images:
# https://hub.docker.com/r/marktmilligan/intellij-idea-community-vnc
#
# Dockerfile:
# https://github.com/sharkymark/dockerfiles/blob/main/intellij-idea/vnc/Dockerfile
#
# parent container image is noVNC and TurboVNC
# https://hub.docker.com/r/marktmilligan/vnc
# tags:
# coder-v2
#
# Dockerfile:
# https://github.com/sharkymark/dockerfiles/tree/main/vnc
/coder/start_vnc >/dev/null 2>&1 

# use coder CLI to clone and install dotfiles
if [[ ! -z "${data.coder_parameter.dotfiles_url.value}" ]]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

# clone repo
if [ ! -d "${local.repo-name}" ]; then
  git clone ${local.repo} >/dev/null 2>&1 &
fi

# start intellij idea community in vnc window
# https://www.jetbrains.com/help/idea/run-for-the-first-time.html#linux
# delay starting intellij in case vnc is not finished setting up
sleep 5
DISPLAY=:90 /opt/idea/bin/idea.sh >/dev/null 2>&1 &

  EOT  
}

resource "coder_app" "novnc" {
  agent_id      = coder_agent.dev.id
  slug          = "vnc"  
  display_name  = "IntelliJ Community in noVNC"
  icon          = "/icon/intellij.svg"
  url           = "http://localhost:6081"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:6081/healthz"
    interval  = 10
    threshold = 15
  } 
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "docker.io/marktmilligan/${local.image}"
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
  item {
    key   = "repo cloned"
    value = "${local.repo-name}"
  }  
}
