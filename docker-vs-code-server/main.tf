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

# dotfiles repo
module "dotfiles" {
    source    = "https://registry.coder.com/modules/dotfiles"
    agent_id  = coder_agent.c.id
}

# microsoft visual studio code server (browser)
module "vscode-web" {
    source         = "https://registry.coder.com/modules/vscode-web"
    agent_id       = coder_agent.c.id
    accept_license = true
    folder         = "/home/coder"
}

# clone a repo
module "git-clone" {
    source   = "https://registry.coder.com/modules/git-clone"
    agent_id = coder_agent.c.id
    url      = data.coder_parameter.repo.value
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
}

data "coder_parameter" "repo" {
  name        = "Source Code Repository"
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
    name = "Golang command line app"
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
  option {
    name = "Shark's rust sample apps"
    value = "https://github.com/sharkymark/rust-hw"
    icon = "https://rustacean.net/assets/cuddlyferris.svg"
  }     
}

data "coder_parameter" "extension" {
  name        = "VS Code extension"
  type        = "string"
  description = "Which VS Code extension do you want?"
  mutable     = true
  default     = "eg2.vscode-npm-script"
  icon        = "/icon/code.svg"

  option {
    name = "npm"
    value = "eg2.vscode-npm-script"
    icon = "https://cdn.freebiesupply.com/logos/large/2x/nodejs-icon-logo-png-transparent.png"
  }
  option {
    name = "Golang"
    value = "golang.go"
    icon = "https://cdn.worldvectorlogo.com/logos/golang-gopher.svg"
  } 
  option {
    name = "rust-lang"
    value = "rust-lang.rust"
    icon = "https://rustacean.net/assets/cuddlyferris.svg"
  } 
  option {
    name = "rust analyzer"
    value = "matklad.rust-analyzer"
    icon = "https://rustacean.net/assets/cuddlyferris.svg"
  }
  option {
    name = "Python"
    value = "ms-python.python"
    icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Python-logo-notext.svg/1869px-Python-logo-notext.svg.png"
  } 
  option {
    name = "Jupyter"
    value = "ms-toolsai.jupyter"
    icon = "/icon/jupyter.svg"
  } 
  option {
    name = "Java"
    value = "redhat.java"
    icon = "https://assets.stickpng.com/images/58480979cef1014c0b5e4901.png"
  }            
}

resource "coder_agent" "c" {
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

  startup_script_behavior = "blocking"
  startup_script_timeout = 300  
  startup_script  = <<EOT
#!/bin/bash

# if rust is the desired programming language, install
if [[ ${data.coder_parameter.repo.value} = "sharkymark/rust-hw.git" ]]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &
fi

# install VS Code extension into vs code server from microsoft's marketplace
sleep 5
/home/coder/.vscode/cli/serve-web/*/bin/code-server --install-extension ${data.coder_parameter.extension.value} &

  EOT  
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "${data.coder_parameter.image.value}"
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"] 

  # Use the docker gateway if the access URL is 127.0.0.1
  #entrypoint = ["sh", "-c", replace(coder_agent.c.init_script, "127.0.0.1", "host.docker.internal")]

  # Use the docker gateway if the access URL is 127.0.0.1
  command = [
    "sh", "-c",
    <<EOT
    trap '[ $? -ne 0 ] && echo === Agent script exited with non-zero code. Sleeping infinitely to preserve logs... && sleep infinity' EXIT
    ${replace(coder_agent.c.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")}
    EOT
  ]


  env        = ["CODER_AGENT_TOKEN=${coder_agent.c.token}"]
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