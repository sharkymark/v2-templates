---
name: Develop in a container in a Docker host with Jupyter Lab or Notebook
description: The goal is to enable Jupyter Lab or Notebook 
tags: [local, docker]
---

# Jupyter Lab & Notebook template for a workspace in a container on a Docker host

### Apps included
1. A web-based terminal
2. Jupyter Lab or Notebook IDE

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user to install Jupyter Lab or Jupyter Notebook (Terraform checks for which type then substitutes arguments when starting the IDE and adding the name into the UI's IDE name)
1. `pip3 install --user` some packages like `pandas`
1. Clone pandas repo
1. Start Jupyter Lab (or Notebook) (it is installed as part of the image)

### Requirements
1. A wildcard subdomain must be enabled (either with Coder's default tunnel or you manually configuring it)

### Known issues
1. The `coder_app` icon (with `subdomain=true`) does not resolve with tunnel if the username, workspace name, and `coder_app` slug make the length of that host segment more than 63 characters. Try shortening the username, slug and workspace name else port forward to `8888` works

### Authentication


### Resources
[JupyterLab docs](https://jupyter-server.readthedocs.io/en/latest/index.html)

[Jupyter Notebook docs](https://jupyter-notebook.readthedocs.io/en/stable/)

[Coder Terraform Provider](https://registry.terraform.io/providers/coder/coder/latest/docs/resources/app)
