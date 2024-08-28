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
  cpu-limit = "1"
  memory-limit = "2G"
  cpu-request = "500m"
  memory-request = "500Mi" 
  home-volume = "10Gi"
  image = "marktmilligan/jupyter:latest"
  repo = "docker.io/sharkymark/pandas_automl.git"
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

data "coder_workspace" "me" {
}

data "coder_workspace_owner" "me" {
}

provider "coder" {

}


data "coder_parameter" "jupyter" {
  name        = "Jupyter IDE type"
  type        = "string"
  description = "What type of Jupyter do you want?"
  mutable     = true
  default     = "lab"
  icon        = "/icon/jupyter.svg"
  order       = 1 

  option {
    name = "Jupyter Lab"
    value = "lab"
    icon = "https://raw.githubusercontent.com/gist/egormkn/672764e7ce3bdaf549b62a5e70eece79/raw/559e34c690ea4765001d4ba0e715106edea7439f/jupyter-lab.svg"
  }
  option {
    name = "Jupyter Notebook"
    value = "notebook"
    icon = "https://codingbootcamps.io/wp-content/uploads/jupyter_notebook.png"
  }       
}

data "coder_parameter" "appshare" {
  name        = "App Sharing"
  type        = "string"
  description = "What sharing level do you want for the IDEs?"
  mutable     = true
  default     = "owner"
  icon        = "/emojis/1f30e.png"

  option {
    name = "Accessible outside the Coder deployment"
    value = "public"
    icon = "/emojis/1f30e.png"
  }
  option {
    name = "Accessible by authenticated users of the Coder deployment"
    value = "authenticated"
    icon = "/emojis/1f465.png"
  } 
  option {
    name = "Only accessible by the workspace owner"
    value = "owner"
    icon = "/emojis/1f510.png"
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

data "coder_parameter" "marketplace" {
  name        = "VS Code Extension Marketplace"
  type        = "string"
  description = "What extension marketplace do you want to use with code-server?"
  mutable     = true
  default     = "ovsx"
  icon        = "/icon/code.svg"

  option {
    name = "Microsoft"
    value = "ms"
    icon = "/icon/microsoft.svg"
  }
  option {
    name = "Open VSX"
    value = "ovsx"
    icon = "https://files.mastodon.social/accounts/avatars/110/249/536/652/270/515/original/bde7b7fef9cef005.png"
  }  
  order       = 4      
}

data "coder_parameter" "api_key" {
  name        = "API Key (optional)"
  description = "Pass an API key to the workspace as an environment variable"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "/emojis/1f511.png"
  order       = 5
}

locals {
  jupyter-type-arg = "${data.coder_parameter.jupyter.value == "notebook" ? "Notebook" : "Server"}"
}

resource "coder_env" "api_key" {
  agent_id = coder_agent.dev.id
  name     = "API_KEY"
  value    = "${data.coder_parameter.api_key.value}"
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
    vscode = false
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = false
    web_terminal = true
  }

  env = { 
    
    }
  startup_script_behavior = "non-blocking"
  startup_script  = <<EOT
#!/bin/sh

set -e

# commented out install the latest code-server since it is already installed in the image
# Append "--version x.x.x" to install a specific version of code-server.
# curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server

# start code-server in the background.
/tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

# start jupyter 
jupyter ${data.coder_parameter.jupyter.value} --${local.jupyter-type-arg}App.token='' --ip='*' --${local.jupyter-type-arg}App.base_url=/@${data.coder_workspace_owner.me.name}/${lower(data.coder_workspace.me.name)}/apps/j >/dev/null 2>&1 &

# clone repo
if [ ! -d "pandas_automl" ]; then
  git clone --progress git@github.com:sharkymark/pandas_automl &
fi


# use coder CLI to clone and install dotfiles
if [ ! -z "${data.coder_parameter.dotfiles_url.value}" ]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

sleep 5

# marketplace
if [ "${data.coder_parameter.marketplace.value}" = "ms" ]; then
  SERVICE_URL=https://marketplace.visualstudio.com/_apis/public/gallery ITEM_URL=https://marketplace.visualstudio.com/items /tmp/code-server/bin/code-server --install-extension ms-toolsai.jupyter 
  SERVICE_URL=https://marketplace.visualstudio.com/_apis/public/gallery ITEM_URL=https://marketplace.visualstudio.com/items /tmp/code-server/bin/code-server --install-extension ms-python.python 
else
  SERVICE_URL=https://open-vsx.org/vscode/gallery ITEM_URL=https://open-vsx.org/vscode/item /tmp/code-server/bin/code-server --install-extension ms-toolsai.jupyter
  SERVICE_URL=https://open-vsx.org/vscode/gallery ITEM_URL=https://open-vsx.org/vscode/item /tmp/code-server/bin/code-server --install-extension ms-python.python
fi

EOT
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.dev.id
  slug          = "cc"  
  display_name  = "code-server"
  icon          = "/icon/code.svg"
  url           = "http://localhost:13337?folder=/home/coder"
  share         = "${data.coder_parameter.appshare.value}"
  subdomain     = false  

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }   
}

resource "coder_app" "jupyter" {
  agent_id      = coder_agent.dev.id
  slug          = "j"  
  display_name  = "jupyter ${data.coder_parameter.jupyter.value}"
  icon          = "/icon/jupyter.svg"
  url           = "http://localhost:8888/@${data.coder_workspace_owner.me.name}/${lower(data.coder_workspace.me.name)}/apps/j"
  share         = "${data.coder_parameter.appshare.value}"
  subdomain     = false  

  healthcheck {
    url       = "http://localhost:8888/healthz"
    interval  = 10
    threshold = 20
  }  
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "${local.image}"
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]

  env        = [
    "CODER_AGENT_TOKEN=${coder_agent.dev.token}"
  ]
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
    value = local.image
  }
  item {
    key   = "repo cloned"
    value = local.repo
  } 
  item {
    key   = "api_key"
    value = data.coder_parameter.api_key.value
    sensitive = true
  } 
  item {
    key   = "jupyter"
    value = "${data.coder_parameter.jupyter.value}"
  }

}
