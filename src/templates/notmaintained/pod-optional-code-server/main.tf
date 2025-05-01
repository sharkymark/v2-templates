terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }   
  }
}

locals {
  folder_name = try(element(split("/", data.coder_parameter.repo.value), length(split("/", data.coder_parameter.repo.value)) - 1), "")  
  repo_owner_name = try(element(split("/", data.coder_parameter.repo.value), length(split("/", data.coder_parameter.repo.value)) - 2), "")
  vscs_install_location = "/tmp/vscode-cli"
  cs_port = "13337"
  cs_log_path = "/tmp/cs.log"
  cs_ext_log_path = "/tmp/cs_extensions.log"    
}

variable "use_kubeconfig" {
  type        = bool
  description = <<-EOF
  Use host kubeconfig? (true/false)

  Set this to false if the Coder host is itself running as a Pod on the same
  Kubernetes cluster as you are deploying workspaces to.

  Set this to true if the Coder host is running outside the Kubernetes cluster
  for workspaces.  A valid "~/.kube/config" must be present on the Coder host.
  EOF
  default = false
}

variable "workspaces_namespace" {
  description = <<-EOF
  Kubernetes namespace to deploy the workspace into

  EOF
  default = ""
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}

data "coder_parameter" "code_server" {
  name        = "code-server"
  description = "Use VS Code in a browser"
  type        = "string"
  default     = "nocs"
  mutable     = true 
  icon        = "/icon/code.svg"
  option {
    name = "No code-server"
    value = "nocs"
    icon = "/emojis/1f6ab.png"
  }   
  option {
    name = "Microsoft VS Code Server"
    value = "vscs"
    icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/Microsoft_icon.svg/240px-Microsoft_icon.svg.png"
  }
  option {
    name = "Coder's code-server"
    value = "cs"
    icon = "/icon/coder.svg"
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

data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "CPU cores for your individual workspace"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min       = 1
    max       = 4
  }
  mutable     = true
  default     = 1
  order       = 3  
}

data "coder_parameter" "memory" {
  name        = "Memory (__ GB)"
  type        = "number"
  description = "Memory (__ GB) for your individual workspace"
  icon        = "https://www.vhv.rs/dpng/d/33-338595_random-access-memory-logo-hd-png-download.png"
  validation {
    min       = 1
    max       = 8
  }
  mutable     = true
  default     = 2
  order       = 4  
}

data "coder_parameter" "disk_size" {
  name        = "PVC storage size"
  type        = "number"
  description = "Number of GB of storage for /home/coder and this will persist even when the workspace's Kubernetes pod and container are shutdown and deleted"
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 1
    max       = 20
    monotonic = "increasing"
  }
  mutable     = true
  default     = 10
  order       = 5  
}

data "coder_parameter" "image" {
  name        = "Container Image"
  type        = "string"
  description = "What container image and language do you want?"
  mutable     = true
  default     = "codercom/enterprise-node:ubuntu"
  icon        = "https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png"

  option {
    name = "Node React"
    value = "codercom/enterprise-node:ubuntu"
    icon = "https://cdn.freebiesupply.com/logos/large/2x/nodejs-icon-logo-png-transparent.png"
  }
  option {
    name = "Golang"
    value = "codercom/enterprise-golang:ubuntu"
    icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Go_Logo_Blue.svg/1200px-Go_Logo_Blue.svg.png"
  } 
  option {
    name = "Java"
    value = "codercom/enterprise-java:ubuntu"
    icon = "https://assets.stickpng.com/images/58480979cef1014c0b5e4901.png"
  } 
  option {
    name = "Base including Python"
    value = "codercom/enterprise-base:ubuntu"
    icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Python-logo-notext.svg/1869px-Python-logo-notext.svg.png"
  }  
  order       = 6      
}

data "coder_parameter" "repo" {
  name        = "Source Code Repository (optional)"
  type        = "string"
  description = "What source code repository do you want to clone?"
  mutable     = true
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  default     = "https://github.com/sharkymark/coder-react"

  option {
    name = "coder-react"
    value = "https://github.com/sharkymark/coder-react"
    icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/React-icon.svg/2300px-React-icon.svg.png"
  }
  option {
    name = "Coder v2 OSS project"
    value = "https://github.com/coder/coder"
    icon = "https://avatars.githubusercontent.com/u/95932066?s=200&v=4"
  }  
  option {
    name = "Coder code-server project"
    value = "https://github.com/coder/code-server"
    icon = "https://avatars.githubusercontent.com/u/95932066?s=200&v=4"
  }
  option {
    name = "Go command line app"
    value = "https://github.com/sharkymark/commissions"
    icon = "https://cdn.worldvectorlogo.com/logos/golang-gopher.svg"
  }
  option {
    name = "Java Hello, World! command line app"
    value = "https://github.com/sharkymark/java_helloworld"
    icon = "https://assets.stickpng.com/images/58480979cef1014c0b5e4901.png"
  }  
  option {
    name = "Python command line app"
    value = "https://github.com/sharkymark/python_commissions"
    icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Python-logo-notext.svg/1869px-Python-logo-notext.svg.png"
  }   
  order       = 7     
}


resource "coder_agent" "coder" {
  os   = "linux"
  arch = "amd64"
  connection_timeout = 300   
  troubleshooting_url = true

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
    ssh_helper = true
    port_forwarding_helper = true
    web_terminal = true
  }
    
  dir = "/home/coder"
  startup_script_behavior = "blocking"
  startup_script = <<EOT
#!/bin/sh

set -e

# clone repo selected by user
if test -z "${data.coder_parameter.repo.value}" 
then
  echo "No git repo specified, skipping"
else
  if [ ! -d "${local.folder_name}" ] 
  then
    echo "💾 Cloning git repo..."
    git clone ${data.coder_parameter.repo.value}
  else
    echo "⛔️ Repo ${data.coder_parameter.repo.value} already exists. Will not reclone"
  fi
  cd ${local.folder_name}
fi

# install and Coder or Microsoft's code-server, VS Code in a browser 

BOLD='\033[0;1m'

if [ ${data.coder_parameter.code_server.value} = "cs" ]; then
  printf "$${BOLD} 🧑🏼‍💻 Downloading and installing the Coder's latest code-server IDE...\n"
  curl -fsSL https://code-server.dev/install.sh | sh
  code-server --auth none --port 13337 >/dev/null 2>&1 &
elif [ ${data.coder_parameter.code_server.value} = "vscs" ]; then

  # Create install directory if it doesn't exist
  mkdir -p ${local.vscs_install_location}

  printf "$${BOLD}Installing Microsoft's vscode-cli!\n"

  # Download and extract code-cli tarball
  output=$(curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz && tar -xf vscode_cli.tar.gz -C ${local.vscs_install_location} && rm vscode_cli.tar.gz)

  if [ $? -ne 0 ]; then
    echo "Failed to install vscode-cli: $output"
    exit 1
  fi
  printf "🥳 vscode-cli has been installed.\n\n"

  echo "🧑🏼‍💻 Running ${local.vscs_install_location}/bin/code serve-web --port ${local.cs_port} --without-connection-token --accept-server-license-terms in the background..."
  echo "Check logs at ${local.cs_log_path}!"
  ${local.vscs_install_location}/code serve-web --port ${local.cs_port} --without-connection-token --accept-server-license-terms --extensions-dir /home/coder/.vscode-server/extensions --log debug >${local.cs_log_path} 2>&1 &

else
  printf "⛔️ VS Code in a browser will not be installed.\n\n"
fi

# use coder CLI to clone and install dotfiles
if [ ! -z "${data.coder_parameter.dotfiles_url.value}" ]; then
  echo "🎨 Cloning a dotfiles repository for personalization..."
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

# authenticate the Coder CLI in the workspace
echo "🔐 Authenticating the Coder CLI..."
coder login ${data.coder_workspace.me.access_url} --token ${data.coder_workspace.me.owner_session_token}

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  count        = data.coder_parameter.code_server.value != "nocs" ? 1 : 0
  agent_id      = coder_agent.coder.id
  slug          = "code-server"  
  display_name  = "code-server"
  icon          = "/icon/code.svg"
  url           = "http://localhost:${local.cs_port}?folder=/home/coder"
  subdomain = data.coder_parameter.code_server.value == "cs" ? "false" : "true"
  share     = "owner"

  healthcheck {
    url       = "http://localhost:${local.cs_port}/healthz"
    interval  = 3
    threshold = 10
  }  
}



resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim.home-directory
  ]  
  metadata {
    name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  spec {
    security_context {
      run_as_user = "1000"
      fs_group    = "1000"
    }    
    container {
      name    = "coder-container"
      image   = "docker.io/${data.coder_parameter.image.value}"
      image_pull_policy = "Always"
      command = ["sh", "-c", coder_agent.coder.init_script]
      security_context {
        run_as_user = "1000"
      }      
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.coder.token
      }  
      resources {
        requests = {
          cpu    = "250m"
          memory = "500Mi"
        }        
        limits = {
          cpu    = "${data.coder_parameter.cpu.value}"
          memory = "${data.coder_parameter.memory.value}G"
        }
      }                       
      volume_mount {
        mount_path = "/home/coder"
        name       = "home-directory"
      }      
    }
    volume {
      name = "home-directory"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.home-directory.metadata.0.name
      }
    }        
  }
}

resource "kubernetes_persistent_volume_claim" "home-directory" {
  metadata {
    name      = "home-coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  wait_until_bound = false    
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.coder_parameter.disk_size.value}Gi"
      }
    }
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "image"
    value = "${data.coder_parameter.image.value}"
  }
  item {
    key   = "repo cloned"
    value = "${local.repo_owner_name}/${local.folder_name}"
  }   
}