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

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 2
}

data "coder_parameter" "ide" {
  name        = "VS Code IDE"
  description = "Select a local or browser-based IDE"
  type        = "string"
  default     = "code"
  mutable     = true
  icon        = "/icon/code.svg"
  order       = 3

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
  option {
    name = "Zed (desktop IDE)"
    value = "zed"
    icon = "/icon/zed.svg"
  }

}

data "coder_parameter" "providermodel" {
  name        = "AI provider and model"
  description = "Select a provider and model for OpenRouter"
  type        = "string"
  default     = "google/gemini-2.0-flash-exp:free"
  mutable     = true
  icon        = "/emojis/2728.png"
  order       = 6

  option {
    name = "google/gemini-2.0-flash-exp:free"
    value = "google/gemini-2.0-flash-exp:free"
  }
  option {
    name = "anthropic/claude-3.7-sonnet"
    value = "anthropic/claude-3.7-sonnet"
  }
  option {
    name = "openai/gpt-4.1"
    value = "openai/gpt-4.1"
  }
}

data "coder_parameter" "ai_prompt" {
  type        = "string"
  name        = "AI Prompt"
  default     = "Write a Python script in a new directory, with a virtual environment, for a number guessing game. The program should generate a random number between 1 and 100, prompt the user to guess it, and provide hints if the guess is too high or too low."
  description = "Write a prompt for Goose"
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

  display_apps {
    vscode = data.coder_parameter.ide.value == "code"
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
    GOOSE_TASK_PROMPT   = data.coder_parameter.ai_prompt.value
    # An API key is required for experiment_auto_configure
    # See https://block.github.io/goose/docs/getting-started/providers
    OPENROUTER_API_KEY = var.openrouter_api_key
  }

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

# zed ide
resource "coder_app" "zed" {
  count = data.coder_parameter.ide.value == "zed" ? 1 : 0
  agent_id = coder_agent.dev.id
  slug          = "slug"
  display_name  = "Zed"
  external = true
  url      = "zed://ssh/coder.${data.coder_workspace.me.name}"
  icon     = "/icon/zed.svg"
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
