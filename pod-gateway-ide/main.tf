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

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 5
}

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
  order       = 1
}

data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "Be sure the cluster nodes have the capacity"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min       = 2
    max       = 6
  }
  mutable     = true
  default     = 4
  order       = 2
}

data "coder_parameter" "memory" {
  name        = "Memory (__ GB)"
  type        = "number"
  description = "Be sure the cluster nodes have the capacity"
  icon        = "https://www.vhv.rs/dpng/d/33-338595_random-access-memory-logo-hd-png-download.png"
  validation {
    min       = 4
    max       = 8
  }
  mutable     = true
  default     = 4
  order       = 3
}

data "coder_parameter" "ide" {

  name        = "JetBrains IDE"
  type        = "string"
  description = "What JetBrains IDE do you want?"
  mutable     = true
  default     = "IntelliJ IDEA Ultimate"
  icon        = "https://resources.jetbrains.com/storage/products/company/brand/logos/jb_beam.svg"
  order       = 4

  option {
    name = "WebStorm"
    value = "WebStorm"
    icon = "/icon/webstorm.svg"
  }
  option {
    name = "GoLand"
    value = "GoLand"
    icon = "/icon/goland.svg"
  } 
  option {
    name = "PyCharm Professional"
    value = "PyCharm Professional"
    icon = "/icon/pycharm.svg"
  } 
  option {
    name = "IntelliJ IDEA Ultimate"
    value = "IntelliJ IDEA Ultimate"
    icon = "/icon/intellij.svg"
  }  

}

locals {
  ide-dir = {
    "IntelliJ IDEA Ultimate" = "idea",
    "PyCharm Professional" = "pycharm",
    "GoLand" = "goland",
    "WebStorm" = "webstorm" 
  } 
  repo-owner = "marktmilligan"
  image = {
    "IntelliJ IDEA Ultimate" = "intellij-idea-ultimate:2023.1",
    "PyCharm Professional" = "pycharm-pro:2023.1",
    "GoLand" = "goland:2022.3.4",
    "WebStorm" = "webstorm:2023.1"
  } 
}

data "coder_parameter" "weather" {
  name        = "Weather"
  type        = "string"
  description = "What city do you want to see the weather for?"
  mutable     = true
  default     = "Austin"
  icon        = "/emojis/1f326.png"

  option {
    name = "Austin, Tex."
    value = "Austin"
    icon = "https://cdn.freebiesupply.com/flags/large/2x/texas-state-flag.png"
  }
  option {
    name = "Fairbanks, Alaska"
    value = "Fairbanks"
    icon = "https://companieslogo.com/img/orig/ALK_BIG.D-04482f4b.png?t=1649480965"
  }  
  option {
    name = "Sydney, Australia"
    value = "Sydney"
    icon = "/emojis/1f1e6-1f1fa.png"
  }  
  option {
    name = "Helsinki, Finland"
    value = "Helsinki"
    icon = "/emojis/1f1eb-1f1ee.png"
  } 
  option {
    name = "Prague, Czech Republic"
    value = "Prague"
    icon = "/emojis/1f1e8-1f1ff.png"
  }     
}

resource "coder_agent" "coder" {
  os   = "linux"

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

  metadata {
    display_name = "Weather"
    key  = "weather"
    # for more info: https://github.com/chubin/wttr.in
    script = <<EOT
        curl -s 'wttr.in/{${data.coder_parameter.weather.value}}?format=3&u' 2>&1 | awk '{print}'
    EOT
    interval = 600
    timeout = 10
  }

  display_apps {
    vscode = false
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = false
    web_terminal = true
  }

  arch = "amd64"
  dir = "/home/coder"
  startup_script = <<EOT
#!/bin/bash

# use coder CLI to clone and install dotfiles
if [[ ! -z "${data.coder_parameter.dotfiles_url.value}" ]]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

# script to symlink JetBrains Gateway IDE directory to image-installed IDE directory
# More info: https://www.jetbrains.com/help/idea/remote-development-troubleshooting.html#setup
cd /opt/${lookup(local.ide-dir, data.coder_parameter.ide.value)}/bin
./remote-dev-server.sh registerBackendLocationForGateway >/dev/null 2>&1 &

  EOT

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
      image   = "docker.io/${local.repo-owner}/${lookup(local.image, data.coder_parameter.ide.value)}"
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
          cpu    = "500m"
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
    value = "${lookup(local.image, data.coder_parameter.ide.value)}"
  }
}