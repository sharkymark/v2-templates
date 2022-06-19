terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.4.2"
    }
  }
}

locals {
  clusters = {
    "🏈 US Central" : {
      name : "master",
      location : "us-central1-a"
    }
    "⚽ Brazil East" : {
      name : "master-brazil",
      location : "southamerica-east1-a"
    }
    "💶 Europe West" : {
      name : "master-europe",
      location : "europe-west2-c"
    }
    "🦘 Australia South" : {
      name : "master-sydney",
      location : "australia-southeast1-b"
    }
  }
}

variable "region" {
  default = "🏈 US Central"
  validation {
    condition     = contains(["🏈 US Central", "⚽ Brazil East", "💶 Europe West", "🦘 Australia South"], var.region)
    error_message = "Must be in the region!"
  }
}

data "google_client_config" "provider" {}

data "google_container_cluster" "my_cluster" {
  project  = "coder-dogfood"
  name     = local.clusters[var.region].name
  location = local.clusters[var.region].location
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
  data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
  )
}

data "coder_workspace" "me" {}
resource "coder_agent" "coder" {
  os   = "linux"
  arch = "amd64"
  dir  = "/home/coder"
  env = {
    COLIN_IS : "cool"
  }
  startup_script = <<-EOF
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 --extensions-dir ~/.vscode-server/extensions/ --user-data-dir ~/.vscode-server/data/ &
~/personalize.sh || true
EOF
}

resource "coder_app" "code-server" {
  agent_id = coder_agent.coder.id
  url = "http://localhost:13337"
  icon = "/code.svg"
}

resource "kubernetes_persistent_volume_claim" "root" {
  metadata {
    name = "home-${data.coder_workspace.me.owner_id}-${data.coder_workspace.me.id}"
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "ssd"
    resources {
      requests = {
        "storage" : "64Gi"
      }
    }
  }
}

resource "coder_metadata" "root" {
  resource_id = kubernetes_persistent_volume_claim.root.id
  name = "Kubernetes Persistent Home"
  env {
    key = "Size"
    value = kubernetes_persistent_volume_claim.root.spec[0].resources.requests["storage"]
  }
}

resource "coder_metadata" "deployment" {
  resource_id = kubernetes_deployment.coder[0].id
  env {
    key = "deployment_name"
    value = kubernetes_deployment.coder[0].metadata.name
  }
  env {
    
  }
}

resource "kubernetes_deployment" "coder" {
  count = data.coder_workspace.me.start_count
  metadata {
    name = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
    labels = {
      "coder.workspace.owner" : data.coder_workspace.me.owner
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "coder.workspace.id" : data.coder_workspace.me.id
      }
    }
    template {
      metadata {
        labels = {
          "coder.workspace.id" = data.coder_workspace.me.id
        }
      }
      spec {
        volume {
          name = "home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.root.metadata[0].name
          }
        }
        volume {
          name = "docker"
          empty_dir {}
        }
        hostname                         = lower(data.coder_workspace.me.name)
        termination_grace_period_seconds = 1
        toleration {
          key      = "com.coder.workspace.preemptible"
          effect   = "NoSchedule"
          operator = "Equal"
          value    = "true"
        }
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "cloud.google.com/gke-preemptible"
                  operator = "In"
                  values   = ["true"]
                }
              }
            }
          }
        }
        container {
          name  = "docker"
          image = "docker:20-dind"
          security_context {
            privileged = true
          }
          env {
            name  = "DOCKER_TLS_CERTDIR"
            value = ""
          }
          volume_mount {
            name       = "docker"
            mount_path = "/var/lib/docker"
          }
        }
        container {
          name    = "dev"
          image   = "gcr.io/coder-dogfood/master/coder-dev-ubuntu:latest"
          command = ["sh", "-c", coder_agent.coder.init_script]
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.coder.token
          }
          env {
            name  = "DOCKER_HOST"
            value = "tcp://localhost:2375"
          }
          volume_mount {
            mount_path = "/home/coder"
            name       = "home"
          }
          security_context {
            run_as_user  = 1000
            run_as_group = 1000
          }
        }
        security_context {
          fs_group = 1000
        }
      }
    }
  }
  timeouts {
    create = "5m"
    delete = "5m"
    update = "5m"
  }
}