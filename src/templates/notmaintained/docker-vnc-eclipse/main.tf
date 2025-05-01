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
  repo_name = "https://github.com/sharkymark/java_helloworld.git"
  folder_name = try(element(split("/", local.repo_name), length(split("/", local.repo_name)) - 1), "") 
  folder_no_git_name = try(element(split(".", local.folder_name), length(split(".", local.folder_name)) - 2), "")  
  repo_owner_name = try(element(split("/", local.repo_name), length(split("/", local.repo_name)) - 2), "")    
  image = "docker.io/marktmilligan/eclipse-vnc:coder-v2"
}


provider "docker" {
  host = var.socket
}

provider "coder" {
}

data "coder_workspace" "me" {
}

data  "coder_workspace_owner" "me" {

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

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 1
}

resource "coder_agent" "dev" {
  arch           = "amd64"
  os             = "linux"

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
    vscode = false
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = false
    web_terminal = true
  }

  startup_script_behavior = "non-blocking"
  startup_script  = <<EOT
#!/bin/sh

# start VNC
echo "Creating desktop..."
mkdir -p "$XFCE_DEST_DIR"
cp -rT "$XFCE_BASE_DIR" "$XFCE_DEST_DIR"
# Skip default shell config prompt.
cp /etc/zsh/newuser.zshrc.recommended $HOME/.zshrc
echo "Initializing Supervisor..."
nohup supervisord >/dev/null 2>&1 &

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 >/dev/null 2>&1 &

# use coder CLI to clone and install dotfiles
if [ ! -z "${data.coder_parameter.dotfiles_url.value}" ]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

# clone repo

echo "git repo owner name: ${local.repo_owner_name}"
echo "git repo folder name: ${local.folder_no_git_name}"

if [ ! -d "${local.folder_no_git_name}" ] 
then
  echo "Cloning git repo..."
  git clone ${local.repo_name}
else
  echo "Repo ${local.repo_name} already exists. Will not reclone"
fi

# eclipse - delay to make sure VNC is running
sleep 5
DISPLAY=:90 /opt/eclipse/eclipse -data /home/coder sh >/dev/null 2>&1 &

  EOT  
}

resource "coder_app" "code-server" {
  agent_id = coder_agent.dev.id
  slug          = "cs"  
  display_name  = "code-server"
  url      = "http://localhost:13337/?folder=/home/coder"
  icon     = "/icon/code.svg"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 15
  }  
}

resource "coder_app" "eclipse" {
  agent_id      = coder_agent.dev.id
  slug          = "e"  
  display_name  = "Eclipse"  
  icon          = "https://upload.wikimedia.org/wikipedia/commons/c/cf/Eclipse-SVG.svg"
  url           = "http://localhost:6081"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:6081/healthz"
    interval  = 6
    threshold = 20
  } 
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = local.image
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]

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
    key   = "git repo owner"
    value = local.repo_owner_name
  }   
  item {
    key   = "repo"
    value = local.folder_no_git_name
  }     
}
