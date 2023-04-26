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
  cpu-request = "500m"
  memory-request = "2" 
  image = "codercom/enterprise-node:ubuntu"
  repo = "sharkymark/coder-react.git"
  repo-name = "coder-react"   
}

#
# on the target k8s cluster run these commands to get host, ca cert and token
#
# then input them as part of the coder templates create or in the coder ui after the template is created
#
# for host: kubectl cluster-info
#
# (optional step if service account already exists in the namespace)
# create a service account token and ca-cert
#
#kubectl apply -n <your namespace> -f - <<EOF
#apiVersion: v1
#kind: ServiceAccount
#metadata:
#  name: coder
#---
#apiVersion: rbac.authorization.k8s.io/v1
#kind: Role
#metadata:
#  name: <your namespace>
#rules:
#  - apiGroups: ["", "apps", "networking.k8s.io"] # "" indicates the core API group
#    resources: ["persistentvolumeclaims", "pods", "deployments", "services", "secrets", "pods/exec","pods/log", "events", "networkpolicies", "serviceaccounts"]
#    verbs: ["create", "get", "list", "watch", "update", "patch", "delete", "deletecollection"]
#  - apiGroups: ["metrics.k8s.io", "storage.k8s.io"]
#    resources: ["pods", "storageclasses"]
#    verbs: ["get", "list", "watch"]
#---
#apiVersion: rbac.authorization.k8s.io/v1
#kind: RoleBinding
#metadata:
#  name: coder
#subjects:
#  - kind: ServiceAccount
#    name: coder
#roleRef:
#  kind: Role
#  name: coder
#  apiGroup: rbac.authorization.k8s.io
#EOF
#
#
# for ca cert and token:
# kubectl get secrets -n <your namespace> -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='coder')].data}{'\n'}"

provider "kubernetes" {
  host                   = var.host
  cluster_ca_certificate = base64decode(var.ca)
  token                  = base64decode(var.token)
}

provider "coder" {
  feature_use_managed_variables = "true"
}

data "coder_provisioner" "me" {
}

variable "ca" {
  sensitive   = true
  description = <<-EOF
  Kubernetes cluster namespace's CA certificate

  EOF
  default = ""
}

variable "token" {
  sensitive   = true
  description = <<-EOF
  Kubernetes cluster namespace's service account token

  EOF
  default = ""
}

variable "host" {
  sensitive   = true
  description = <<-EOF
  Kubernetes cluster host

  EOF
  default = ""
}

variable "namespace" {
  sensitive   = true
  description = <<-EOF
  Kubernetes cluster namespace

  EOF
  default = ""
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
  name        = "PVC (your $HOME directory) storage size"
  type        = "number"
  description = "Number of GB of storage"
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 1
    max       = 10
    monotonic = "increasing"
  }
  mutable     = true
  default     = 10
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


resource "coder_agent" "coder" {
  os                      = "linux"

  metadata {
    key          = "disk"
    display_name = "Home Volume Disk Usage"
    interval     = 600 # every 10 minutes
    timeout      = 30  # df can take a while on large filesystems
    script       = <<-EOT
      #!/bin/bash
      set -e
      df /home/coder | awk NR==2'{print $5}'
    EOT
  }

  metadata {
    key          = "mem-used"
    display_name = "Memory Usage"
    interval     = 1
    timeout      = 1
    script       = <<-EOT
      #!/bin/bash
      set -e
      awk '(NR == 1){tm=$1} (NR == 2){mu=$1} END{printf("%.0f%%",mu/tm * 100.0)}' /sys/fs/cgroup/memory/memory.limit_in_bytes /sys/fs/cgroup/memory/memory.usage_in_bytes
    EOT
  } 


    metadata {
    key          = "cpu-used"
    display_name = "CPU Usage"
    interval     = 3
    timeout      = 3
    script       = <<-EOT
      #!/bin/bash
      set -e

      tstart=$(date +%s%N)
      cstart=$(cat /sys/fs/cgroup/cpu/cpuacct.usage)

      sleep 1

      tstop=$(date +%s%N)
      cstop=$(cat /sys/fs/cgroup/cpu/cpuacct.usage)

      echo "($cstop - $cstart) / ($tstop - $tstart) * 100" | /usr/bin/bc -l | awk '{printf("%.0f%%",$1)}'      

    EOT
  }

  arch                    = data.coder_provisioner.me.arch
  dir                     = "/home/coder"
  env                     = { "DOTFILES_URI" = data.coder_parameter.dotfiles_url.value != "" ? data.coder_parameter.dotfiles_url.value : null }    
  startup_script = <<EOT
#!/bin/sh

# install bench/basic calculator
sudo apt install bc 

# use coder CLI to clone and install dotfiles
if [ -n "$DOTFILES_URI" ]; then
  echo "Installing dotfiles from $DOTFILES_URI"
  coder dotfiles -y "$DOTFILES_URI"
fi

# install and start the latest code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 &

# clone repo
if [ ! -d "${local.repo-name}" ]; then
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone ${local.repo}
fi

  EOT  
}


# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  slug          = "code-server"  
  display_name  = "VS Code Web"
  icon          = "/icon/code.svg"
  url           = "http://localhost:13337?folder=/home/coder"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
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
    namespace = var.namespace
  }
  spec {
    security_context {
      run_as_user = "1000"
      fs_group    = "1000"
    }    
    container {
      name    = "coder-container"
      image   = local.image
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
          cpu    = data.coder_parameter.cpu.value
          memory = "${data.coder_parameter.cpu.value}G"
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
    namespace = var.namespace
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
    key   = "CPU"
    value = "${data.coder_parameter.cpu.value} cores"
  }
  item {
    key   = "memory"
    value = "${data.coder_parameter.memory.value}G"
  }  
  item {
    key   = "disk"
    value = "${data.coder_parameter.disk_size.value}GiB"
  }
  item {
    key   = "image"
    value = local.image
  }
}