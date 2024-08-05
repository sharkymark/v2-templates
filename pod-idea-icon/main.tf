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

  # 2023-12-30 switch from deprecated coder java image to custom image
  #   1. with jdk 11 and build tools maven 3.9.6, gradle 8.5
  #   2. ide, build number change - former values: ideaIU-2023.2.5 | 232.10203.10
  #   3. Added coder_parameter to adjust disk size; jetbrains ides can fill up space
  # 2023-11-23 ide, build number change - former values: ideaIU-2023.2 | 232.9921.47

locals {
  cpu-limit = "4"
  memory-limit = "8G"
  cpu-request = "500m"
  memory-request = "1" 
  home-volume = "30Gi"
  #repo = "iluwatar/java-design-patterns.git"
  repo = "https://github.com/sharkymark/java_helloworld.git" 
  repo-name = "java_helloworld" 
  repo-owner = "docker.io/marktmilligan"
  image = "java:jdk-11" 

  # jetbrains product codes https://plugins.jetbrains.com/docs/marketplace/product-codes.html
  ide_product_code = "IU"
  # jetbrains builds https://www.jetbrains.com/idea/download/other.html   
  ide_build_number = "241.17890.1"   
  # IDE release downloads https://data.services.jetbrains.com/products/releases?code=IU
  ide = "ideaIU-2024.1.4"
  ide_download_link = "https://download.jetbrains.com/idea/${local.ide}.tar.gz"  
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

variable "namespace" {
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

data "coder_workspace_owner" "me" {}

data "coder_parameter" "disk_size" {
  name        = "PVC storage size"
  type        = "number"
  description = "Number of GB of storage for /home/coder and this will persist even when the workspace's Kubernetes pod and container are shutdown and deleted"
  icon        = "/emojis/1f4be.png"
  validation {
    min       = 10
    max       = 100
    monotonic = "increasing"
  }
  mutable     = true
  default     = 30
  order       = 1  
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "/icon/dotfiles.svg"
  order       = 2
}

data "coder_provisioner" "me" {
}

resource "coder_agent" "coder" {
  os                      = "linux"
  arch                    = data.coder_provisioner.me.arch
  connection_timeout = 300   
  troubleshooting_url = true

 # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  metadata {
    display_name = "pod CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "pod RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "pvc Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  } 


  dir                     = "/home/coder"
  startup_script_behavior = "blocking"

  display_apps {
    vscode = false
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = false
    web_terminal = true
  }

  env                     = {  }    
  startup_script = <<EOT
#!/bin/bash

set -e

# use coder CLI to clone and install dotfiles
if [[ ! -z "${data.coder_parameter.dotfiles_url.value}" ]]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

# clone java repo

# clone repo selected by user
if [ ! -d "${local.repo-name}" ] 
then
  echo "Cloning git repo..."
  git clone ${local.repo}
else
  echo "Repo ${local.repo-name} already exists. Will not reclone"
fi

  EOT  
}

resource "coder_app" "gateway" {
  agent_id     = coder_agent.coder.id
  display_name = "IntelliJ Ultimate"
  slug         = "gateway"
  url          = "jetbrains-gateway://connect#type=coder&workspace=${data.coder_workspace.me.name}&agent=coder&folder=/home/coder/&url=${data.coder_workspace.me.access_url}&token=${data.coder_workspace_owner.me.session_token}&ide_product_code=${local.ide_product_code}&ide_build_number=${local.ide_build_number}&ide_download_link=${local.ide_download_link}"
  icon         = "/icon/intellij.svg"
  external     = true
}

resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim.home-directory
  ]  
  metadata {
    name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
    namespace = var.namespace
  }
  spec {
    security_context {
      run_as_user = "1000"
      fs_group    = "1000"
    }    
    container {
      name    = "coder-container"
      image   = "${local.repo-owner}/${local.image}"
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
          cpu    = local.cpu-request
          memory = local.memory-request
        }        
        limits = {
          cpu    = local.cpu-limit
          memory = local.memory-limit
        }
      }                       
      volume_mount {
        mount_path = "/home/coder"
        name       = "home-directory"
        read_only  = false
      }      
    }
    volume {
      name = "home-directory"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.home-directory.metadata.0.name
        read_only  = false
      }
    }        
  }
}



resource "kubernetes_persistent_volume_claim" "home-directory" {
  metadata {
    name      = "home-coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
    namespace = var.namespace
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = local.home-volume
      }
    }
  }
}

resource "coder_metadata" "home-directory" {
    resource_id = kubernetes_persistent_volume_claim.home-directory.id
    daily_cost  = 10
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  daily_cost  = 20
  item {
    key   = "image"
    value = local.image
  } 
  item {
    key   = "ide & build #"
    value = "${local.ide} | ${local.ide_build_number}"
  }   
  item {
    key   = "repo"
    value = local.repo-name
  }       
}

