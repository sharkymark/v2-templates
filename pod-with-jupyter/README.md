---
name: Develop with Jupyter in a container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and Jupyter Lab or Jupyter Notebook
tags: [cloud, kubernetes]
---

# Jupyter Lab & Notebook and code-server (VS Code) template for a workspace in a Kubernetes pod

### Changes 2024-08-05

1. Notice use of `data.coder_workspace_owner.me`, a new 2024 Coder change in their Terraform provider that replaced `data.coder_workspace.me.owner`
1. Coder deprecated its Ubuntu Jupter image so I built one based on Coder's base image and put on DockerHub

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. Jupyter Lab or Notebook IDE
1. Metadata about image, compute and what was installed

### Additional bash scripting
1. Prompt user for Kubernetes namespace to create pod
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user to install Jupyter Lab or Jupyter Notebook (Terraform checks for which type then substitutes arguments when starting the IDE and adding the name into the UI's IDE name)
1. `pip3 install --user` some packages like `pandas`
1. Prompt user for compute options (CPU core, memory, and disk)
1. Clone pandas repo
1. Install Jupyter VS Code extension
1. Start Jupyter Lab (or Notebook) (it is installed as part of the image)
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. Alternatively, developers can run localhost and either use `coder port-forward <workspace name> --tcp 8888:8888` or `ssh -L 8888:localhost:8888 coder.<workspace name>`

### Sharing

There is a `coder_parameter` called `appshare` where the user can decide if the IDEs can be shared to other Coder deployment users, external to the deployment, or only the workspace owner.

```hcl
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
  order       = 2      
}
```

```hcl
resource "coder_app" "jupyter" {
  agent_id      = coder_agent.coder.id
  slug          = "j"  
  display_name  = "jupyter ${data.coder_parameter.jupyter.value}"
  icon          = "/icon/jupyter.svg"
  url           = "http://localhost:8888/"
  share         = "${data.coder_parameter.appshare.value}"
  subdomain     = true  

  healthcheck {
    url       = "http://localhost:8888/healthz/"
    interval  = 10
    threshold = 20
  }  
}
```

### Authentication

This template will use a service account to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable during template creation to the Kubernetes namespace the workspace will be deployed to

### Resources
[JupyterLab docs](https://jupyter-server.readthedocs.io/en/latest/index.html)

[Jupyter Notebook docs](https://jupyter-notebook.readthedocs.io/en/stable/)

[Coder Terraform Provider](https://registry.terraform.io/providers/coder/coder/latest/docs/resources/app)

[pandas Jupyter notebook and data sets repo](https://github.com/sharkymark/pandas_automl)
