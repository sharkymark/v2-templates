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

# 2023-12-03 added amazon codewhisperer extension to go image and install to code-server in startup_script

locals {
  folder_name = try(element(split("/", data.coder_parameter.repo.value), length(split("/", data.coder_parameter.repo.value)) - 1), "")  
  repo_owner_name = try(element(split("/", data.coder_parameter.repo.value), length(split("/", data.coder_parameter.repo.value)) - 2), "") 

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

# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/pod#image_pull_policy
variable "image_pull_policy" {
  description = "Container image pull policy e.g., Always, Never, IfNotPresent"
  default     = "Always"
  validation {
    condition = contains([
      "Always",
      "Never",
      "IfNotPresent",
    ], var.image_pull_policy)
    error_message = "Invalid image pull policy!"   
}
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}

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
  order       = 3  
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
  order       = 1  
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
  order       = 2  
}

data "coder_parameter" "image" {
  name        = "Container Image"
  type        = "string"
  description = "The Go container image"
  mutable     = true
  default     = "marktmilligan/go:1.21.5"
  icon        = "/icon/go.svg"

  option {
    name = "Latest 1.21.5"
    value = "marktmilligan/go:1.21.5"
    icon = "/icon/github.svg"
  }

  option {
    name = "1.21.4"
    value = "marktmilligan/go:1.21.4"
    icon = "/icon/github.svg"
  }
  option {
    name = "1.21.0"
    value = "marktmilligan/go:1.21.0"
    icon = "/icon/github.svg"
  }
  option {
    name = "1.20.4"
    value = "marktmilligan/go:1.20.4"
  } 
  option {
    name = "1.20.1"
    value = "marktmilligan/go:1.20.1"
  } 
  option {
    name = "1.19.6"
    value = "marktmilligan/go:1.19.6"
  }  
  order       = 4      
}

data "coder_parameter" "genai" {
  name        = "GenAI VS Code extension"
  type        = "string"
  description = "Choose a Generative AI VS Code Extension"
  mutable     = true
  default     = "copilot"
  icon        = "/icon/github.svg"
  order       = 5  
  option {
    name = "GitHub Copilot"
    value = "copilot"
    icon = "/icon/github.svg"
  }
  option {
    name = "AWS Code Whisperer"
    value = "aws"
    icon = "/icon/aws.png"
  }  
  option {
    name = "Tabnine"
    value = "tabnine"
    icon = "https://aeiljuispo.cloudimg.io/v7/https://cdn-uploads.huggingface.co/production/uploads/1667479339476-60e31139c1d1c861782ce7f3.png"
  }   
}

data "coder_parameter" "repo" {
  name        = "Source Code Repository"
  type        = "string"
  description = "What source code repository do you want to clone?"
  mutable     = true
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  default     = "https://github.com/coder/coder"

  option {
    name = "Coder v2 OSS project"
    value = "https://github.com/coder/coder"
    icon = "https://avatars.githubusercontent.com/u/95932066?s=200&v=4"
  }  
  option {
    name = "Go command line app"
    value = "https://github.com/sharkymark/commissions"
    icon = "https://cdn.worldvectorlogo.com/logos/golang-gopher.svg"
  }   
  order       = 6     
}

data "coder_parameter" "weather" {
  name        = "Weather"
  type        = "string"
  description = "What city do you want to see the weather for?"
  mutable     = true
  default     = "Austin"
  icon        = "/emojis/1f326.png"
  order       = 7

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
    name = "Pittsburgh, Pennsylvania"
    value = "Pittsburgh"
    icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Pittsburgh_Steelers_logo.svg/2048px-Pittsburgh_Steelers_logo.svg.png"
  } 
  option {
    name = "New York City"
    value = "nyc"
    icon = "https://pngimg.com/d/statue_of_liberty_PNG33.png"
  }   
  option {
    name = "Albany, New York"
    value = "albany"
    icon = "https://icon2.cleanpng.com/20180703/yba/kisspng-brooklyn-t-shirt-apple-fifth-avenue-big-apple-i-lo-5b3af70b8dc472.4576895015305909875807.jpg"
  }  
  option {
    name = "Cupertino, California"
    value = "@apple.com"
    icon = "/icon/apple-grey.svg"
  }   
  option {
    name = "Miami, Florida"
    value = "miami"
    icon = "/emojis/1f34a.png"
  }   
  option {
    name = "Abu Dhabi UAE"
    value = "AbuDhabi"
    icon = "https://upload.wikimedia.org/wikipedia/commons/1/1e/UAE_EMBLEM.png"
  }     
  option {
    name = "Prague, Czech Republic"
    value = "Prague"
    icon = "/emojis/1f1e8-1f1ff.png"
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
    name = "Provo, Utah"
    value = "Provo"
    icon = "/emojis/1f3d4.png"
  } 
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 8
}

resource "coder_agent" "coder" {
  os   = "linux"
  arch = "amd64"

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
    vscode = true
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = false
    web_terminal = false
  }

  dir = "/home/coder"
  startup_script_behavior = "blocking"
  startup_script_timeout = 300  
  startup_script = <<EOT
#!/bin/bash

# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server
/tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

# clone repo
if test -z "${data.coder_parameter.repo.value}" 
then
  echo "No git repo specified, skipping"
else
  if [[ ! -d "${local.folder_name}" ]] 
  then
    echo "Cloning git repo..."
    git clone ${data.coder_parameter.repo.value}
  else
    echo "Repo ${data.coder_parameter.repo.value} already exists. Will not reclone"
  fi
  cd ${local.folder_name}
fi

# gopls language server
go install -v golang.org/x/tools/gopls@latest

# install genai extensions from container image
if [[ ${data.coder_parameter.genai.value == "copilot"} ]]; then
  /tmp/code-server/bin/code-server --install-extension /coder/vsix/GitHub.copilot.vsix
  /tmp/code-server/bin/code-server --install-extension /coder/vsix/GitHub.copilot-chat.vsix
elif [[ ${data.coder_parameter.genai.value == "aws"} ]]; then
  /tmp/code-server/bin/code-server --install-extension /coder/vsix/AmazonWebServices.aws-toolkit-vscode.vsix
elif [[ ${data.coder_parameter.genai.value == "tabnine"} ]]; then
  /tmp/code-server/bin/code-server --install-extension /coder/vsix/TabNine.tabnine-vscode.vsix
fi

# install extension from external open-vsix marketplace
SERVICE_URL=https://open-vsx.org/vscode/gallery ITEM_URL=https://open-vsx.org/vscode/item /tmp/code-server/bin/code-server --install-extension golang.Go >/dev/null 2>&1 &


# use coder CLI to clone and install dotfiles
if [[ ! -z "${data.coder_parameter.dotfiles_url.value}" ]]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  slug          = "code-server"  
  display_name  = "code-server"
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

resource "kubernetes_deployment" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim.home-directory
  ]   
  wait_for_rollout = false
  metadata {
    name = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
    namespace = var.workspaces_namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace.me.owner_id
      "com.coder.user.username"    = data.coder_workspace.me.owner
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace.me.owner_email
    }    
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "coder-workspace"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "coder-workspace"
        }
      }
   
      spec {

        security_context {
          run_as_user = "1000"
          fs_group    = "1000"
        }          
        container {
          name    = "coder-container"
          image   = "docker.io/${data.coder_parameter.image.value}"
          image_pull_policy = "${var.image_pull_policy}"
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
              memory = "512Mi"
            }        
            limits = {
              cpu    = "${data.coder_parameter.cpu.value}"
              memory = "${data.coder_parameter.memory.value}Gi"
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
        affinity {
          // This affinity attempts to spread out all workspace pods evenly across
          // nodes.
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["coder-workspace"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "home-directory" {
  metadata {
    name      = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}-home"
    namespace = var.workspaces_namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
      "app.kubernetes.io/part-of"  = "coder"
      //Coder-specific labels
      "com.coder.resource"       = "true"
      "com.coder.workspace.id"   = data.coder_workspace.me.id
      "com.coder.workspace.name" = data.coder_workspace.me.name
      "com.coder.user.id"        = data.coder_workspace.me.owner_id
      "com.coder.user.username"  = data.coder_workspace.me.owner
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace.me.owner_email
    }
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
  resource_id = kubernetes_deployment.main[0].id
  item {
    key   = "image"
    value = "${data.coder_parameter.image.value}"
  }
  item {
    key   = "repo cloned"
    value = "${local.repo_owner_name}/${local.folder_name}"
  }   
}