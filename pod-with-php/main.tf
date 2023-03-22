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

  cpu-request = "250m"
  memory-request = "2" 
  #base-image = "docker.io/marktmilligan/phpstorm-vscode:2021.3.3"   
  base-image = "docker.io/marktmilligan/phpstorm-vscode:2022.1.4"  
  #base-image = "docker.io/codercom/enterprise-base:ubuntu"    
}

provider "coder" {
  feature_use_managed_variables = "true"
}

variable "use_kubeconfig" {
  type        = bool
  sensitive   = true
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
  sensitive   = true
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
  name        = "Dotfiles URL"
  description = "Personalize your workspace"
  type        = "string"
  default     = "git@github.com:sharkymark/dotfiles.git"
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

data "coder_parameter" "disk_size" {
  name        = "PVC storage size"
  type        = "number"
  description = "Number of GB of storage"
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 1
    max       = 10
    monotonic = "increasing"
  }
  mutable     = true
  default     = 5
}

data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "Be sure the cluster nodes have the capacity"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min       = 1
    max       = 4
  }
  mutable     = true
  default     = 1
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
  default     = 2
}

resource "coder_agent" "main" {
  os             = "linux"
  arch           = "amd64"
  dir            = "/home/coder"
  startup_script = <<EOF
    #!/bin/sh

    ${data.coder_parameter.dotfiles_url.value != "" ? "coder dotfiles -y ${data.coder_parameter.dotfiles_url.value} &" : ""}

    # Configure and run JetBrains IDEs in a web browser
    # https://www.jetbrains.com/phpstorm/download/other.html
    # Using JetBrains projector; please migrate to Gateway
    # https://lp.jetbrains.com/projector/
    # https://coder.com/docs/v2/latest/ides/gateway

    # Assumes you have JetBrains IDE installed in /opt
    # and pip3 installed in
    # your image and the "coder" user has filesystem
    # permissions for "/opt/*"
   
    pip3 install projector-installer --user
    /home/coder/.local/bin/projector --accept-license 
    
    /home/coder/.local/bin/projector config add ps /opt/ps --force --use-separate-config --port 9001 --hostname localhost
    /home/coder/.local/bin/projector run ps &

    # create symbolic link for JetBrains Gateway
    /opt/ps/bin/remote-dev-server.sh registerBackendLocationForGateway

    # clone 2 php repos
    mkdir -p ~/.ssh
    ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
    git clone --progress git@github.com:sharkymark/original_php.git
    git clone --progress git@github.com:sharkymark/php_helloworld.git

    # install VS Code extensions for PHP development and debugging
    SERVICE_URL=https://open-vsx.org/vscode/gallery ITEM_URL=https://open-vsx.org/vscode/item code-server --install-extension KnisterPeter.vscode-github &

    SERVICE_URL=https://open-vsx.org/vscode/gallery ITEM_URL=https://open-vsx.org/vscode/item code-server --install-extension felixfbecker.php-debug &

    # Start code-server
    code-server --auth none --disable-file-downloads --port 13337 &

    # start PHP servers
    cd ~/original_php
    setsid /usr/bin/php -S 0.0.0.0:1026 -t . >/home/coder/phpapp2.log 2>&1 < /home/coder/phpapp2.log & 

    cd ~/php_helloworld
    setsid /usr/bin/php -S 0.0.0.0:1027 -t . >/home/coder/phpapp1.log 2>&1 < /home/coder/phpapp1.log & 

  EOF
}

# code-server
resource "coder_app" "code-server" {
  agent_id = coder_agent.main.id
  slug          = "code-server"  
  display_name  = "VS Code Web"
  icon     = "/icon/code.svg"
  url      = "http://localhost:13337"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }  

}

resource "coder_app" "php" {
  agent_id = coder_agent.main.id
  slug          = "ps"  
  display_name  = "PhpStorm Web"  
  icon          = "/icon/phpstorm.svg"
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
      image   = local.base-image
      image_pull_policy = "Always"
      command = ["sh", "-c", coder_agent.main.init_script]
      security_context {
        run_as_user = "1000"
      }      
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.main.token
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
    key   = "kubernetes namespace"
    value = "${var.workspaces_namespace}"
  }    
  item {
    key   = "CPU (limits, requests)"
    value = "${data.coder_parameter.cpu.value} cores, ${kubernetes_pod.main[0].spec[0].container[0].resources[0].requests.cpu}"
  }
  item {
    key   = "memory (limits, requests)"
    value = "${data.coder_parameter.memory.value}, ${kubernetes_pod.main[0].spec[0].container[0].resources[0].requests.memory}"
  }    
  item {
    key   = "image"
    value = kubernetes_pod.main[0].spec[0].container[0].image
  }
  item {
    key   = "container image pull policy"
    value = kubernetes_pod.main[0].spec[0].container[0].image_pull_policy
  }   
  item {
    key   = "disk"
    value = data.coder_parameter.disk_size.value
  }
  item {
    key   = "volume"
    value = kubernetes_pod.main[0].spec[0].container[0].volume_mount[0].mount_path
  }  
  item {
    key   = "security context - container"
    value = "run_as_user ${kubernetes_pod.main[0].spec[0].container[0].security_context[0].run_as_user}"
  }   
  item {
    key   = "security context - pod"
    value = "run_as_user ${kubernetes_pod.main[0].spec[0].security_context[0].run_as_user} fs_group ${kubernetes_pod.main[0].spec[0].security_context[0].fs_group}"
  }     
}
