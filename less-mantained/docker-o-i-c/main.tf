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

}

provider "coder" {

}

data "coder_parameter" "git_repo_url" {
  name        = "Git Repo URL"
  description = "The `https` URL to your git repo - using your GitHub OAuth token"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

locals {
  image = "codercom/enterprise-node:ubuntu"
  folder_name = try(element(split("/", data.coder_parameter.git_repo_url.value), length(split("/", data.coder_parameter.git_repo_url.value)) - 1), "")
}

data "coder_git_auth" "github" {
  # Matches the ID of the git auth provider in Coder.
  id = "primary-github"
}

resource "coder_agent" "dev" {
  arch           = "amd64"
  os             = "linux"

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.

# 2023-07-12 commenting out since fails on docker
#  metadata {
#    display_name = "CPU Usage"
#    key          = "0_cpu_usage"
#    script       = "coder stat cpu"
#    interval     = 10
#    timeout      = 1
#  }

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

  env = {
    GITHUB_TOKEN : data.coder_git_auth.github.access_token
  }

  startup_script  = <<EOT
#!/bin/bash

# clone repo
if test -z "${data.coder_parameter.git_repo_url.value}" 
then
  echo "No git repo specified, skipping"
else
  if [ ! -d "${local.folder_name}" ] 
  then
    echo "Cloning git repo..."
    git clone ${data.coder_parameter.git_repo_url.value}
  fi
  cd ${local.folder_name}
fi

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 &

  EOT  
}

resource "coder_app" "code-server" {
  agent_id = coder_agent.dev.id
  slug          = "code-server"  
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

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "${local.image}"
  # Uses lower() to avoid Docker restriction on container names.
  name     = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  hostname = lower(data.coder_workspace.me.name)
  dns      = ["1.1.1.1"]

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
