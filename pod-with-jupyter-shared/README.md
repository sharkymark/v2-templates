---
name: Share a Jupyter IDE with teammates in a container in a Kubernetes pod
description: The goal is to let a Jupyter IDE be shared
tags: [cloud, kubernetes]
---

# Sharable Jupyter template for a workspace in a Kubernetes pod

### Apps included

1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. Jupyter Lab or Notebook IDE
1. Metadata about image, compute and what was installed

### Additional bash scripting

1. Prompt user for Kubernetes namespace to create pod
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for $HOME volume size
1. Prompt user if they want teammates to be able to use their Jupyter IDE
1. Prompt user to install Jupyter Lab or Jupyter Notebook (Terraform checks for which type then substitutes arguments when starting the IDE and adding the name into the UI's IDE name)
1. `pip3 install --user` some packages like `pandas`
1. Clone pandas repo
1. Install Jupyter VS Code extension
1. Start Jupyter Lab (or Notebook) (it is installed as part of the image)
1. Download, install and start code-server (VS Code-in-a-browser)

### Prompt user for sharing level

> `public` sharing is commented out and is not recommended for an IDE. A production scenario may just hard-code the sharing level in the template and not allow the developer to define it.

```hcl
data "coder_parameter" "sharable" {
  name        = "Jupyter sharability"
  type        = "string"
  description = "Share your Jupyter IDE?"
  mutable     = true
  default     = "owner"
  icon        = "https://www.citypng.com/public/uploads/small/11640440543fbutyemz4zzymlbb6qjwkdd6kq4cxcybj08zrqj8rxbgcj3kdu1pxuz86ilokdt8434yosamazw4rsh60bwhf3onig4ti59fu034.png"

  option {
    name = "Only You - No Sharing"
    value = "owner"
  }
  option {
    name = "Share with anyone authenticated to your Coder deployment"
    value = "authenticated"
  }
#  option {
#    name = "Share with anyone outside of your Coder deployment"
#    value = "public"
#  }
}
```

### Sharing Jupyter settings

```hcl
resource "coder_app" "jupyter" {
  agent_id      = coder_agent.coder.id
  slug          = "j"
  display_name  = "jupyter ${data.coder_parameter.jupyter.value}"
  icon          = "/icon/jupyter.svg"
  url           = "http://localhost:8888/"
  share         = "${data.coder_parameter.sharable.value}"
  subdomain     = true

  healthcheck {
    url       = "http://localhost:8888/healthz"
    interval  = 10
    threshold = 20
  }
}
```

### Known limitations

1. A wildcard subdomain or starting Coder with `tunnel` is required to access Jupyter

### Authentication

This template will use a service account to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable during template creation to the Kubernetes namespace the workspace will be deployed to

### Resources

[Coder docs on sharing port forwarding](https://coder.com/docs/v2/latest/networking/port-forwarding#from-an-coder_app-resource)

[JupyterLab docs](https://jupyter-server.readthedocs.io/en/latest/index.html)

[Jupyter Notebook docs](https://jupyter-notebook.readthedocs.io/en/stable/)

[Coder Terraform Provider](https://registry.terraform.io/providers/coder/coder/latest/docs/resources/app)

[pandas Jupyter notebook and data sets repo](https://github.com/sharkymark/pandas_automl)
