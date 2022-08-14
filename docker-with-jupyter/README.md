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
1. `pip3 install --user` some packages like `pandas` and `numpy`
1. Prompt user to install Jupyter Lab or Jupyter Notebook (Terraform checks for which type then substitutes arguments when starting the IDE and adding the name into the UI's IDE name)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Clone repo
1. Start Jupyter IDE 
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. Alternatively, developers can run localhost and either use `coder port-forward <workspace name> --tcp 8888:8888` or `ssh -L 8888:localhost:8888 coder.<workspace name>`
1. A `--NotebookApp.base_url` or `--ServerApp.base_url` parameter in the `startup_script` where Jupyter Notebook or Lab is started, must be set to owner and workspace path for the browser to know how to reach the workspace.
1. A `coder_app` resource `url` for Jupyter Notebook must be set to owner and workspace path for the browser to know how to reach the workspace.

### Authentication


### Resources
[coder-react repo](https://github.com/mark-theshark/coder-react)
[code-server releases](https://github.com/coder/code-server/releases)
