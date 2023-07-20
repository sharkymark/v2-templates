---
name: Develop with Jupyter in a container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and Jupyter Lab or Jupyter Notebook
tags: [cloud, kubernetes]
---

# Jupyter Lab & Notebook and code-server (VS Code) template for a workspace in a Kubernetes pod

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

### Requirements
1. With the `coder_app` `subdomain=false`, the workspace owner and workspace name must be added to the Jupyter `baseURL` in the `startup_script` and the `url` part of the `coder_app`

```sh
# start jupyter 
jupyter ${var.jupyter} --${local.jupyter-type-arg}App.token='' --ip='*' --${local.jupyter-type-arg}App.base_url=/@${data.coder_workspace.me.owner}/${lower(data.coder_workspace.me.name)}/apps/j &
```


```hcl
resource "coder_app" "jupyter" {
  agent_id      = coder_agent.coder.id
  slug          = "j"  
  display_name  = "jupyter-${var.jupyter}"
  icon          = "/icon/jupyter.svg"
  url           = "http://localhost:8888/@${data.coder_workspace.me.owner}/${lower(data.coder_workspace.me.name)}/apps/j"
  share         = "owner"
  subdomain     = false  

  healthcheck {
    url       = "http://localhost:8888/healthz"
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
