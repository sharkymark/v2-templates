resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count  
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "CPU cores"
    value = "${var.cpu}G"
  }
  item {
    key   = "memory"
    value = "${var.memory}G"
  }
  item {
    key   = "Kubernetes namespace"
    value = "${var.workspaces_namespace}"
  }
  item {
    key   = "Container image"
    value = "${var.image}"
  }  
  item {
    key   = "Source Code repo"
    value = "${var.repo}"
  }  
  item {
    key   = "VS Code extension"
    value = "${var.extension}"
  } 
  item {
    key   = "Source Code repo"
    value = "${var.repo}"
  }   
}