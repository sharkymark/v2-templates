---
name: Develop in a container in a Docker host with Jupyter Lab or Notebook
description: The goal is to enable Jupyter Lab or Notebook 
tags: [local, docker]
---

# Jupyter Lab & Notebook template for a workspace in a container on a Docker host

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. Jupyter Lab or Notebook IDE

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user to install Jupyter Lab or Jupyter Notebook (Terraform checks for which type then substitutes arguments when starting the IDE and adding the name into the UI's IDE name)
1. `pip3 install --user` some packages like `pandas`
1. Clone pandas repo
1. Install Jupyter VS Code extension
1. Start Jupyter Lab (or Notebook) (it is installed as part of the image)
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. Alternatively, developers can run localhost and either use `coder port-forward <workspace name> --tcp 8888:8888` or `ssh -L 8888:localhost:8888 coder.<workspace name>`

### Breaking changes
1. This template uses functionality in the Coder provider 0.6.0 for the `coder_app` called `slug` and `display_name`
1. Also removed the baseURL from the Jupyter startup script and the owner and workspace names from the `coder_app`

### Authentication


### Resources
[coder-react repo](https://github.com/mark-theshark/coder-react)
[code-server releases](https://github.com/coder/code-server/releases)
[Coder Terraform Provider](https://registry.terraform.io/providers/coder/coder/latest/docs/resources/app)
