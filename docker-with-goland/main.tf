terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.4.2"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.17.0"
    }
  }
}

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)

  see https://dotfiles.github.io
  EOF
  default = ""
}

variable "image" {
  description = <<-EOF
  Container images from coder-com

  EOF
  default = "codercom/enterprise-golang:ubuntu"
  validation {
    condition = contains([
      "codercom/enterprise-golang:ubuntu"
    ], var.image)
    error_message = "Invalid image!"   
}  
}

variable "extension" {
  description = "VS Code extension"
  default     = "golang.go"
  validation {
    condition = contains([
      "golang.go"
    ], var.extension)
    error_message = "Invalid VS Code extension!"  
}
}

variable "repo" {
  description = <<-EOF
  Code repository to clone with SSH
  e.g., mark-theshark/commissions.git
  EOF
  default = ""
}

variable "folder_path" {
  description = <<-EOF
 Folder to add to VS Code (optional)
e.g.,
/home/coder (default)
  EOF
  default = "/home/coder"
}

variable "code-server" {
  description = "code-server release"
  default     = "4.5.0"
  validation {
    condition = contains([
      "4.5.0",
      "4.4.0",
      "4.3.0",
      "4.2.0"
    ], var.code-server)
    error_message = "Invalid code-server!"   
}
}

variable "jetbrains-ide" {
  description = "JetBrains GoLand IDE (oldest are Projector-tested by JetBrains s.r.o., Na Hrebenech II 1718/10, Prague, 14000, Czech Republic)"
  default     = "GoLand 2022.1.3"
  validation {
    condition = contains([
      "GoLand 2022.1.3",
      "GoLand 2021.3.5",
      "GoLand 2020.3.5"
    ], var.jetbrains-ide)
    error_message = "Invalid JetBrains IDE!"   
}
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "coder" {
}

data "coder_workspace" "me" {
}


resource "coder_agent" "coder" {
  os   = "linux"
  arch = "amd64"
  dir = "/home/coder"
  startup_script = <<EOT
#!/bin/bash

# use coder CLI to clone and install dotfiles

coder dotfiles -y ${var.dotfiles_uri} 2>&1 | tee dotfiles.log

# install projector into /home/coder

PROJECTOR_BINARY=/home/coder/.local/bin/projector

if [ -f $PROJECTOR_BINARY ]; then
    echo 'projector has already been installed - check for update'
    /home/coder/.local/bin/projector self-update 2>&1 | tee projector.log
else
    echo 'installing projector'
    pip3 install projector-installer --user 2>&1 | tee projector.log
fi

echo 'access projector license terms'
/home/coder/.local/bin/projector --accept-license 2>&1 | tee -a projector.log

PROJECTOR_CONFIG_PATH=/home/coder/.projector/configs/goland

if [ -d "$PROJECTOR_CONFIG_PATH" ]; then
    echo 'projector has already been configured and the JetBrains IDE downloaded - skip step' | tee -a projector.log
else
    echo 'autoinstalling IDE and creating projector config folder'
    /home/coder/.local/bin/projector ide autoinstall --config-name "goland" --ide-name "${var.jetbrains-ide}" --hostname=localhost --port 8997 --use-separate-config --password coder | tee -a projector.log

    # delete the configuration's run.sh input parameters that check password tokens since tokens do not work with coder_app yet passed in the querystring

    grep -iv "HANDSHAKE_TOKEN" $PROJECTOR_CONFIG_PATH/run.sh > temp && mv temp $PROJECTOR_CONFIG_PATH/run.sh | tee -a projector.log
    chmod +x $PROJECTOR_CONFIG_PATH/run.sh | tee -a projector.log

    echo "creation of goland configuration complete" | tee -a projector.log
    
fi

# install JetBrains projector packages required
sudo apt-get update && \
    DEBIAN_FRONTEND="noninteractive" sudo apt-get install -y \
    libxtst6 \
    libxrender1 \
    libfontconfig1 \
    libxi6 \
    libgtk-3-0 | tee -a projector.log

# start JetBrains projector-based IDE
/home/coder/.local/bin/projector run goland &

# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh 2>&1 | tee code-server-install.log
code-server --auth none --port 13337 2>&1 | tee code-server-install.log &

# clone repo
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
git clone --progress git@github.com:${var.repo} 2>&1 | tee repo-clone.log

# install VS Code extensions into code-server
SERVICE_URL=https://open-vsx.org/vscode/gallery ITEM_URL=https://open-vsx.org/vscode/item code-server --install-extension ${var.extension} 2>&1 | tee vs-code-extension.log

EOT
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  name          = "code-server"
  icon          = "/icon/code.svg"
  url           = "http://localhost:13337?folder=${var.folder_path}"
  relative_path = true  
}

resource "coder_app" "goland" {
  agent_id      = coder_agent.coder.id
  name          = "${var.jetbrains-ide}"
  icon          = "/icon/goland.svg"
  url           = "http://localhost:8997/"
  relative_path = true
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "${var.image}"
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["sh", "-c", replace(coder_agent.coder.init_script, "127.0.0.1", "host.docker.internal")]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.coder.token}"]
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