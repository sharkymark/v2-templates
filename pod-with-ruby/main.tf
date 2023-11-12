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

provider "coder" {

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

data "coder_parameter" "disk_size" {
  name        = "PVC storage size"
  type        = "number"
  description = "Number of GB of storage"
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 1
    max       = 20
    monotonic = "increasing"
  }
  mutable     = true
  default     = 10
  order       = 3
}

data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "CPU cores - be sure the cluster nodes have the capacity"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min       = 1
    max       = 4
  }
  mutable     = true
  default     = 4
  order       = 1
}

data "coder_parameter" "memory" {
  name        = "Memory (__ GB)"
  type        = "number"
  description = "Be sure the cluster nodes have the capacity"
  icon        = "https://www.vhv.rs/dpng/d/33-338595_random-access-memory-logo-hd-png-download.png"
  validation {
    min       = 1
    max       = 8
  }
  mutable     = true
  default     = 4
  order       = 2
}

data "coder_parameter" "appshare" {
  name        = "App Sharing"
  type        = "string"
  description = "What sharing level do you want on the Survey app?"
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
  order       = 4      
}

# dotfiles repo
module "dotfiles" {
    source    = "https://registry.coder.com/modules/dotfiles"
    agent_id  = coder_agent.dev.id
}

# coder's code-server (vs code in browser)
module "code-server" {
    source    = "https://registry.coder.com/modules/code-server"
    agent_id  = coder_agent.dev.id
    folder    = "/home/coder"
}

# clone a repo
module "git-clone" {
    source   = "https://registry.coder.com/modules/git-clone"
    agent_id = coder_agent.dev.id
    url      = "https://github.com/sharkymark/rubyonrails"
}

# download rubymine jetbrains ide and open jetbrains gateway
module "jetbrains_gateway" {
  source         = "https://registry.coder.com/modules/jetbrains-gateway"
  agent_id       = coder_agent.dev.id
  agent_name     = "dev"
  folder         = "/home/coder/rubyonrails"
  jetbrains_ides = ["RM"]
  default         = "RM"
}

resource "coder_agent" "dev" {
  os             = "linux"
  arch           = "amd64"

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

  dir = "/home/coder"
  env = { 
    }
  startup_script_behavior = "blocking"
  startup_script_timeout = 300   
  startup_script = <<EOF
  #!/bin/sh  

    # Configure and run JetBrains IDEs in a web browser
    # https://www.jetbrains.com/pycharm/download/other.html
    # Using JetBrains projector; please migrate to Gateway
    # https://lp.jetbrains.com/projector/
    # https://coder.com/docs/v2/latest/ides/gateway

    # Assumes you have JetBrains IDE installed in /opt
    # and pip3 installed in
    # your image and the "coder" user has filesystem
    # permissions for "/opt/*"
   
    pip3 install projector-installer --user
    /home/coder/.local/bin/projector --accept-license 
    
    /home/coder/.local/bin/projector config add rubymine1 /opt/rubymine --force --use-separate-config --port 9001 --hostname localhost
    /home/coder/.local/bin/projector run rubymine1 >/dev/null 2>&1 &

    # symlink to jetbrains rubymine
    if [ ! -L "$HOME/.cache/JetBrains/RemoteDev/userProvidedDist/_opt_rubymine" ]; then
        /opt/rubymine/bin/remote-dev-server.sh registerBackendLocationForGateway >/dev/null 2>&1 &
    fi  

    # Ruby on Rails app - employee survey
    
    # bundle Ruby gems
    cd ~/rubyonrails
    bundle config set --local path './bundled-gems'
    bundle install
    # start Rails server as daemon
    rails s -p 3002 -b 0.0.0.0 -d  

  EOF
}

resource "coder_script" "shutdown" {
  agent_id      = coder_agent.dev.id
  display_name  = "Stop Rails daemon server"
  run_on_stop   = true
  icon          = "/emojis/1f6d1.png"
  script        = <<EOF
  #!/bin/sh 
    kill $(lsof -i :3002 -t)
  EOF
}


# employee survey
resource "coder_app" "employeesurvey" {
  agent_id = coder_agent.dev.id
  slug          = "survey"  
  display_name  = "Survey"
  icon     = "https://cdn.iconscout.com/icon/free/png-256/hacker-news-3521477-2944921.png"
  url      = "http://localhost:3002"
  subdomain = true
  share     = "${data.coder_parameter.appshare.value}"

  healthcheck {
    url       = "http://localhost:3002/healthz"
    interval  = 10
    threshold = 30
  }  

}

resource "coder_app" "rubymine1" {
  agent_id = coder_agent.dev.id
  slug          = "rm"  
  display_name  = "RubyMine (browser)"  
  icon          = "/icon/rubymine.svg"
  url           = "http://localhost:9001"
  subdomain     = false
  share         = "owner"

  healthcheck {
    url         = "http://localhost:9001/healthz"
    interval    = 6
    threshold   = 20
  }    
}

resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim.home-directory
  ]
  metadata {
    name      = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  spec {
    security_context {
      run_as_user = 1000
      fs_group    = 1000
    }
    container {
      name    = "dev"
      image   = "docker.io/marktmilligan/ruby-2-7-2:rm-2023.2.5"
      image_pull_policy = "Always"       
      command = ["sh", "-c", coder_agent.dev.init_script]
      security_context {
        run_as_user = "1000"
      }
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.dev.token
      }
      resources {
        requests = {
          cpu    = "250m"
          memory = "250Mi"
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
    name      = "coder-pvc-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
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
    key   = "kubernetes namespace"
    value = "${var.workspaces_namespace}"
  }       
  item {
    key   = "image"
    value = kubernetes_pod.main[0].spec[0].container[0].image
  }     
}
