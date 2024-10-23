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
  folder_name = try(element(split("/", data.coder_parameter.repo.value), length(split("/", data.coder_parameter.repo.value)) - 1), "")  
  repo_owner_name = try(element(split("/", data.coder_parameter.repo.value), length(split("/", data.coder_parameter.repo.value)) - 2), "")    
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

data "coder_parameter" "image" {
  name        = "Container Image"
  type        = "string"
  description = "What container image and language do you want?"
  mutable     = true
  default     = "marktmilligan/node:22.7.0"
  icon        = "https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png"

  option {
    name = "Node React"
    value = "marktmilligan/node:22.7.0"
    icon = "/icon/node.svg"
  }
  option {
    name = "Go"
    value = "marktmilligan/go:1.23.0"
    icon = "/icon/go.svg"
  } 
  option {
    name = "Base including Python"
    value = "codercom/enterprise-base:ubuntu"
    icon = "/icon/python.svg"
  }
  order       = 1        
}

data "coder_parameter" "repo" {
  name        = "Source Code Repository"
  type        = "string"
  description = "What source code repository do you want to clone?"
  mutable     = true
  icon        = "/icon/git.svg"
  default     = ""
  option {
    name = "Do not clone a repository"
    value = ""
    icon = "/emojis/274c.png"
  }
  option {
    name = "Node React Hello, World"
    value = "https://github.com/sharkymark/coder-react"
    icon = "/icon/node.svg"
  }
  option {
    name = "Coder CDE OSS Go project"
    value = "https://github.com/coder/coder"
    icon = "/icon/coder.svg"
  }  
  option {
    name = "Python CLI app for calculating sales commissions"
    value = "https://github.com/sharkymark/python_commissions"
    icon = "/icon/python.svg"
  }
  order       = 2       
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 3
}

data "coder_parameter" "ide" {
  name        = "VS Code IDE"
  description = "Select a local or browser-based IDE"
  type        = "string"
  default     = "code"
  mutable     = true 
  icon        = "/icon/code.svg"
  order       = 5

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

# use coder CLI to clone and install dotfiles
if [ ! -z "${data.coder_parameter.dotfiles_url.value}" ]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

# clone repo

echo "folder_name: ${local.folder_name}"
echo "repo_name: ${local.repo_owner_name}"

if test -z "${data.coder_parameter.repo.value}" 
then
  echo "No git repo specified, skipping"
else
  if [ ! -d "${local.folder_name}" ] 
  then  
    echo "Cloning git repo..."
    git clone ${data.coder_parameter.repo.value}
  else
    echo "directory and repo ${local.folder_name} exists, so skipping clone"
  fi
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
  image = "${data.coder_parameter.image.value}"
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
    value = "${data.coder_parameter.image.value}"
  }
  item {
    key   = "repo cloned"
    value = "${local.repo_owner_name}/${local.folder_name}"
  }  
}
