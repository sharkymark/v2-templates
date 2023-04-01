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

data "coder_workspace" "me" {
}

provider "docker" {
  host = "tcp://docker-proxy:2375"
}

provider "coder" {
  feature_use_managed_variables = "true"
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL"
  description = "Personalize your workspace"
  type        = "string"
  default     = "git@github.com:sharkymark/dotfiles.git"
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
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
  default     = "sharkymark/coder-react.git"

  option {
    name = "coder-react"
    value = "sharkymark/coder-react.git"
    icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/React-icon.svg/2300px-React-icon.svg.png"
  }
  option {
    name = "Coder v2 OSS project"
    value = "coder/coder.git"
    icon = "https://avatars.githubusercontent.com/u/95932066?s=200&v=4"
  }  
  option {
    name = "Coder code-server project"
    value = "coder/code-server.git"
    icon = "https://avatars.githubusercontent.com/u/95932066?s=200&v=4"
  }
  option {
    name = "Golang command line app"
    value = "sharkymark/commissions.git"
    icon = "https://cdn.worldvectorlogo.com/logos/golang-gopher.svg"
  }
  option {
    name = "Java Hello, World! command line app"
    value = "sharkymark/java_helloworld.git"
    icon = "https://assets.stickpng.com/images/58480979cef1014c0b5e4901.png"
  }  
  option {
    name = "Python command line app"
    value = "sharkymark/python_commissions.git"
    icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Python-logo-notext.svg/1869px-Python-logo-notext.svg.png"
  }
  option {
    name = "Shark's rust sample apps"
    value = "sharkymark/rust-hw.git"
    icon = "https://rustacean.net/assets/cuddlyferris.svg"
  }     
}

data "coder_parameter" "extension" {
  name        = "VS Code extension"
  type        = "string"
  description = "Which VS Code extension do you want?"
  mutable     = true
  default     = "golang.go"
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

resource "coder_agent" "dev" {
  arch           = "amd64"
  os             = "linux"
  startup_script  = <<EOT
#!/bin/bash

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 &

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${data.coder_parameter.dotfiles_url.value} &

# if rust is the desired programming languge, install
if [[ ${data.coder_parameter.repo.value} = "sharkymark/rust-hw.git" ]]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &
fi

# install VS Code extension into code-server
SERVICE_URL=https://open-vsx.org/vscode/gallery ITEM_URL=https://open-vsx.org/vscode/item code-server --install-extension ${data.coder_parameter.extension.value} &

# clone repo
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone git@github.com:${data.coder_parameter.repo.value} &

  EOT  
}

resource "coder_app" "code-server" {
  agent_id = coder_agent.dev.id
  slug          = "code-server"  
  display_name  = "VS Code Web"
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

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "${data.coder_parameter.image.value}"
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
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
  name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
}
