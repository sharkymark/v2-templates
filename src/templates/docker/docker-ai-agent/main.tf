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

}

provider "docker" {
  host = var.socket
}

provider "coder" {
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

variable "openrouter_api_key" {
  type        = string
  description = "The OpenRouter API key"
  sensitive   = true
}

module "goose" {
  source        = "registry.coder.com/modules/goose/coder"
  agent_id      = coder_agent.dev.id
  folder        = "/home/coder"
  install_goose = true
  experiment_report_tasks = true
  experiment_auto_configure = true
  experiment_use_screen = true
  experiment_goose_provider = "openrouter"
  experiment_goose_model = "${data.coder_parameter.providermodel.value}"  
}

module "coder-login" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/coder-login/coder"
  agent_id = coder_agent.dev.id
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

module "git-config" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/git-config/coder"
  agent_id = coder_agent.dev.id
}

data "coder_parameter" "image" {
  name        = "Container Image"
  type        = "string"
  description = "What container image and language do you want?"
  mutable     = true
  default     = "marktmilligan/python:latest"
  icon        = "https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png"

  option {
    name = "Python"
    value = "marktmilligan/python:latest"
    icon = "/icon/python.svg"
  }
  order       = 1
}

data "coder_parameter" "providermodel" {
  name        = "AI provider and model"
  description = "Select a provider and model for OpenRouter"
  type        = "string"
  default     = "openai/gpt-4o-mini"
  mutable     = true
  icon        = "/emojis/2728.png"
  order       = 6

  option {
    name = "google/gemini-2.0-flash-001"
    value = "google/gemini-2.0-flash-001"
  }
    option {
    name = "google/gemini-2.5-flash-preview"
    value = "google/gemini-2.5-flash-preview"
  }
  option {
    name = "anthropic/claude-3.7-sonnet"
    value = "anthropic/claude-3.7-sonnet"
  }
   option {
    name = "anthropic/claude-3.5-sonnet"
    value = "anthropic/claude-3.5-sonnet"
  } 
  option {
    name = "openai/gpt-4.1"
    value = "openai/gpt-4.1"
  }
  option {
    name = "openai/gpt-4o-mini"
    value = "openai/gpt-4o-mini"
  }  
}

data "coder_parameter" "ai_prompt" {
  type        = "string"
  name        = "AI Prompt"
  description = "Write a prompt for Goose"
  default      = ""
  mutable     = true
  icon        = "/emojis/2728.png"
  order       = 7  
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
  connection_timeout = 300

  env = {

    GOOSE_SYSTEM_PROMPT = <<-EOT
      You are a helpful assistant that can help write code.

      Run all long running tasks (e.g. npm run dev) in the background and not in the foreground.

      Periodically check in on background tasks.

      Notify Coder of the status of the task before and after your steps.
    EOT
    # Only set GOOSE_TASK_PROMPT if ai_prompt has a value
    GOOSE_TASK_PROMPT   = length(data.coder_parameter.ai_prompt.value) > 0 ? data.coder_parameter.ai_prompt.value : null
    # An API key is required for experiment_auto_configure
    # See https://block.github.io/goose/docs/getting-started/providers
    OPENROUTER_API_KEY = var.openrouter_api_key
  }

  startup_script  = <<EOT
#!/bin/sh

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
}
