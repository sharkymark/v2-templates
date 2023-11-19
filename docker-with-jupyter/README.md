---
name: Develop in a container in a Docker host with JupyterLab
description: The goal is to enable JupyterLab 
tags: [local, docker]
---

# JupyterLab template for a workspace in a container on a Docker host

### Apps included
1. A web-based terminal
2. JupyterLab IDE
3. code-server IDE

### Coder modules

This template uses modules from Coder's registry

1. [Module](https://registry.coder.com/modules/jupyterlab) to install JupyterLab IDE
1. [Module](https://registry.coder.com/modules/code-server) to install code-server IDE and Jupyter and Python extensions
1. [Module](https://registry.coder.com/modules/dotfiles) to clone a dotfiles repo for workspace 
personalization

### Additional scripting

1. add the pandas Python package

```sh
pip3 install --user pandas &
```

### Requirements
1. A wildcard subdomain must be enabled (either with Coder's default tunnel or you manually configuring it)


### Resources
[JupyterLab docs](https://jupyter-server.readthedocs.io/en/latest/index.html)

[Jupyter Notebook docs](https://jupyter-notebook.readthedocs.io/en/stable/)

[Coder Terraform Provider](https://registry.terraform.io/providers/coder/coder/latest/docs)
