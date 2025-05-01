---
name: Develop with Jupyter in a container in a Kubernetes pod
description: The goal is to clone a Python repo and enable code-server (VS Code) and Jupyter Lab or Jupyter Notebook
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
1. Clone pandas repo specified in the code repository Open in Coder button
1. Install Jupyter VS Code extension
1. Start Jupyter Lab (or Notebook) (it is installed as part of the image)
1. Download, install and start code-server (VS Code-in-a-browser)


### Authentication

This template will use a service account to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable during template creation to the Kubernetes namespace the workspace will be deployed to

### Resources
[JupyterLab docs](https://jupyter-server.readthedocs.io/en/latest/index.html)

[Jupyter Notebook docs](https://jupyter-notebook.readthedocs.io/en/stable/)

[Coder Terraform Provider](https://registry.terraform.io/providers/coder/coder/latest/docs/resources/app)

[pandas Jupyter notebook and data sets repo](https://github.com/sharkymark/pandas_automl)
