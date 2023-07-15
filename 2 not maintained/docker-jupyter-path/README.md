---
name: Develop in a container in a Docker host with Jupyter Lab or Notebook on a path, not a subdomain
description: The goal is to enable Jupyter Lab or Notebook on a path, not a subdomain
tags: [local, docker]
---

# Jupyter Lab & Notebook template for a workspace in a container on a Docker host, on a path, not a subdomain

### Apps included
1. A web-based terminal
2. Jupyter Lab or Notebook IDE
3. `code-server` VS Code Web IDE

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user to install Jupyter Lab or Jupyter Notebook (Terraform checks for which type then substitutes arguments when starting the IDE and adding the name into the UI's IDE name)
1. `pip3 install --user` some packages like `pandas`
1. Clone pandas repo
1. Start Jupyter Lab (or Notebook) (it is installed as part of the image)
1. Download and start `code-server` VS Code Web IDE

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


### Resources
[JupyterLab docs](https://jupyter-server.readthedocs.io/en/latest/index.html)

[Jupyter Notebook docs](https://jupyter-notebook.readthedocs.io/en/stable/)

[Coder Terraform Provider](https://registry.terraform.io/providers/coder/coder/latest/docs/resources/app)
