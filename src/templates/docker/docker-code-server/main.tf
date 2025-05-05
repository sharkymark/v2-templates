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
  default     = "marktmilligan/go:latest"
  icon        = "https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png"

  option {
    name = "Node React"
    value = "marktmilligan/node:22.7.0"
    icon = "/icon/node.svg"
  }
  option {
    name = "Go"
    value = "marktmilligan/go:latest"
    icon = "/icon/go.svg"
  }
  option {
    name = "Python and AI agents Goose and Aider"
    value = "marktmilligan/python-ai-agents:latest"
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
  default     = "https://github.com/coder/coder"
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

data "coder_parameter" "git_user_name" {
  type        = "string"
  name        = "Git user.name"
  description = "Used to run: git config --global user.name"
  default     = ""
  mutable     = true
  icon        = "/emojis/1f511.png"
  order       = 3 
}

data "coder_parameter" "git_user_email" {
  type        = "string"
  name        = "Git user.email"
  description = "Used to run: git config --global user.email"
  default     = ""
  mutable     = true
  icon        = "/emojis/1f511.png"
  order       = 4  
}


data "coder_parameter" "github_user_name" {
  type        = "string"
  name        = "GitHub username"
  description = "Used to run: git config --global credential...username"
  default     = ""
  mutable     = true
  icon        = "/emojis/1f511.png"
  order       = 5  
}

data "coder_parameter" "github_personal_access_token" {
  type        = "string"
  name        = "GitHub personal access token"
  description = "Used to run with git credential-store store"
  default     = ""
  mutable     = true
  icon        = "/emojis/1f511.png"
  order       = 6
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
  extensions     = ["github.copilot"]
  folder         = "/home/coder"
  accept_license = true
}

module "git-clone" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/git-clone/coder"
  version  = "1.0.18"
  agent_id = coder_agent.dev.id
  url      = "${data.coder_parameter.repo.value}"
}

module "coder-login" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/coder-login/coder"
  agent_id = coder_agent.dev.id
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
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
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
    port_forwarding_helper = true
    web_terminal = true
  }

  startup_script_behavior = "non-blocking"
  connection_timeout = 300
  startup_script  = <<EOT
  #!/bin/sh

  # configure git username and email for commits
  if [ ! -z "${data.coder_parameter.git_user_name.value}" ]; then
    git config --global user.name "${data.coder_parameter.git_user_name.value}"
  fi
  if [ ! -z "${data.coder_parameter.git_user_email.value}" ]; then
    git config --global user.email "${data.coder_parameter.git_user_email.value}"
  fi
  # configure git credential helper for github
  if [ ! -z "${data.coder_parameter.github_user_name.value}" ]; then
    git config --global credential.https://github.com.username "${data.coder_parameter.github_user_name.value}"
  fi

  if [ ! -z "${data.coder_parameter.github_personal_access_token.value}" ]; then
    git config --global credential.helper store
    printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n" "${data.coder_parameter.github_user_name.value}" "${data.coder_parameter.github_personal_access_token.value}" | git credential-store store
  fi

  EOT
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
