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
  repo_url = data.coder_parameter.repo.value == "custom" ? data.coder_parameter.custom_repo_url.value : data.coder_parameter.repo.value
  folder_name = replace(
    try(element(split("/", local.repo_url), length(split("/", local.repo_url)) - 1), ""),
    ".git",
    "")
  repo_owner_name = try(element(split("/", local.repo_url), length(split("/", local.repo_url)) - 2), "")    
  image = "ghcr.io/coder/envbuilder:latest"
  # Find the latest version here:
  # https://github.com/coder/envbuilder/tags  
}

data "coder_parameter" "repo" {
  name         = "repo"
  display_name = "Repository"
  order        = 1
  description  = "Select a repository to automatically clone and start working with a devcontainer."
  mutable      = true
  option {
    name        = "sharkymark/envbuilder-starter-devcontainer"
    description = "An example repository for getting started with devcontainer.json and envbuilder."
    value       = "https://github.com/sharkymark/envbuilder-starter-devcontainer"
    icon        = "https://avatars.githubusercontent.com/u/95932066?s=200&v=4"
  }
  option {
    name        = "microsoft/vscode-remote-try-go"
    description = "Golang"
    value       = "https://github.com/microsoft/vscode-remote-try-go"
    icon        = "https://cdn.worldvectorlogo.com/logos/golang-gopher.svg"
  }
  option {
    name        = "microsoft/vscode-remote-try-node"
    description = "Node.js"
    value       = "https://github.com/microsoft/vscode-remote-try-node"
    icon        = "https://cdn.freebiesupply.com/logos/large/2x/nodejs-icon-logo-png-transparent.png"
  } 
  option {
    name        = "microsoft/vscode-remote-try-java"
    description = "Java"
    value       = "https://github.com/microsoft/vscode-remote-try-java"
    icon        = "https://assets.stickpng.com/images/58480979cef1014c0b5e4901.png"
  }
  option {
    name        = "Custom"
    icon        = "/emojis/1f5c3.png"
    description = "Specify a custom repo URL below"
    value       = "custom"
  }
}

data "coder_parameter" "custom_repo_url" {
  name         = "custom_repo"
  display_name = "Repository URL (custom)"
  order        = 2
  default      = ""
  description  = "Optionally enter a custom repository URL, see [awesome-devcontainers](https://github.com/manekinekko/awesome-devcontainers)."
  mutable      = true
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

data "coder_workspace" "me" {
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

data "coder_workspace_owner" "me" {
}

module "dotfiles" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/dotfiles/coder"
  agent_id = coder_agent.main.id
}

module "vscode-web" {
  count          = data.coder_workspace.me.start_count
  source         = "registry.coder.com/modules/vscode-web/coder"
  agent_id       = coder_agent.main.id
  extensions     = ["github.copilot"]
  accept_license = true
  folder         = "/workspaces/${local.folder_name}"
}

module "coder-login" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/coder-login/coder"
  agent_id = coder_agent.main.id
}

resource "coder_agent" "main" {
  arch           = "amd64"
  os             = "linux"
  dir            = "/workspaces"

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

  display_apps {
    vscode = true
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = true
    web_terminal = true
  }

  startup_script_behavior = "non-blocking"
  connection_timeout = 600  
  startup_script  = <<EOT
#!/bin/bash

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
  # Find the latest version here:
  # https://github.com/coder/envbuilder/tags
  image = local.image
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.me.name

  # Use the docker gateway if the access URL is 127.0.0.1
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "CODER_AGENT_URL=${replace(data.coder_workspace.me.access_url, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}",
    "GIT_URL=${data.coder_parameter.repo.value == "custom" ? data.coder_parameter.custom_repo_url.value : data.coder_parameter.repo.value}",
    "INIT_SCRIPT=${replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}",
    "FALLBACK_IMAGE=ubuntu" # This image runs if builds fail
  ]
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/workspaces"
    volume_name    = docker_volume.workspaces.name
    read_only      = false
  }

}

resource "docker_volume" "workspaces" {
  name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }  
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.workspace[0].id    
}
