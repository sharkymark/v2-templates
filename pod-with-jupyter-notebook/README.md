---
name: Develop with Jupyter Notebook in a container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and Jupyter Notebook
tags: [cloud, kubernetes]
---

# JupyterLab IDE and code-server (VS Code) template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. Jupyter Notebook IDE

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. `pip3 install --user` some packages like `pandas` and `numpy`
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Clone repo
1. Start Jupyter Notebook (it is installed as part of the image)
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. Alternatively, developers can run localhost and either use `coder port-forward <workspace name> --tcp 8888:8888` or `ssh -L 8888:localhost:8888 coder.<workspace name>`
1. A `--NotebookApp.base_url` parameter in the `startup_script` where Jupyter Notebook is started, must be set to owner and workspace path for the browser to know how to reach the workspace.
1. A `coder_app` resource `url` for Jupyter Notebook must be set to owner and workspace path for the browser to know how to reach the workspace.

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[JupyterLab docs](https://jupyter-server.readthedocs.io/en/latest/index.html)
