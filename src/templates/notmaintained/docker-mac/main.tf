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

provider "coder" {
  feature_use_managed_variables = "true"
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

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL"
  description = "Personalize your workspace"
  type        = "string"
  default     = "git@github.com:sharkymark/dotfiles.git"
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

data "coder_workspace" "me" {
}

resource "coder_agent" "dev" {
  arch = "amd64"
  os   = "darwin"

  metadata {
  display_name = "Disk Usage"
  key  = "disk"
  script = "df -h | awk '$6 ~ /^\\/$/ { print $5 }'"
  interval = 600
  timeout = 1
  }

  startup_script_behavior = "blocking"
  startup_script_timeout = 300 

  startup_script  = <<EOT
#!/bin/bash

# install and start microsoft visual studio code server
wget -O- https://aka.ms/install-vscode-server/setup.sh | sh
code-server --accept-server-license-terms serve-local --without-connection-token --quality stable --telemetry-level off >/dev/null 2>&1 &

# use coder CLI to clone and install dotfiles
if [[ ! -z "${data.coder_parameter.dotfiles_url.value}" ]]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

# install vs code extension into microsoft's code-server from microsoft's marketplace
code-server serve-local --install-extension GitHub.copilot >/dev/null 2>&1 &

  EOT 

}

# microsoft vs code server
resource "coder_app" "msft-code-server" {
  agent_id      = coder_agent.dev.id
  slug          = "msft"  
  display_name  = "VS Code Server"
  icon          = "/icon/code.svg"
  url           = "http://localhost:8000?folder=/home/coder"
  subdomain = true
  share     = "owner"

  healthcheck {
    url       = "http://localhost:8000/healthz"
    interval  = 5
    threshold = 15
  }  
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  dns   = ["1.1.1.1"]
  devices {
    host_path = "/dev/kvm"
  }
  env   = ["OSX_COMMANDS=/bin/bash -c 'export CODER_AGENT_TOKEN=${coder_agent.dev.token} && ${coder_agent.dev.init_script}'", "TERMS_OF_USE=i_agree", "EXTRA=-display none -vnc 0.0.0.0:5900,password=off"]
  image = "sickcodes/docker-osx:auto"
  name  = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-root"
}
