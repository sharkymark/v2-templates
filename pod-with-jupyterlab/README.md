---
name: Develop with JupyterLab in a container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and JupyterLab
tags: [cloud, kubernetes]
---

# JupyterLab IDE and code-server (VS Code) template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. Jupyter Lab IDE

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. `pip3 install --user` some packages like `pandas` and `numpy`
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Clone repo
1. Start JupyterLab (it is installed as part of the image)
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. Coder OSS currently does not have dev URL functionality built-in, so to run JupyterLab, developers either use `coder port-forward <workspace name> --tcp 8888:8888` or `ssh -L 8888:localhost:8888 coder.<workspace name>`
1. Note that a `jupyter-lab` `coder_app` is not in this template since dev URLs are needed for that to work. I've made attempts to pass `--ServerApp.base_url='./'` or substituting the path from an opened `coder_app` IDE like code-server, but no joy yet.

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[JupyterLab docs](https://jupyter-server.readthedocs.io/en/latest/index.html)
