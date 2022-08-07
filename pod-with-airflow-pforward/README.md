---
name: Develop with Airflow in a container in a Kubernetes pod
description: The goal is to enable Airflow and code-server (VS Code)
tags: [cloud, kubernetes]
---

# Airflow IDE and code-server (VS Code) template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. Airflow IDE

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. `pip3 install --user` some packages like `pandas` and `numpy`
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Clone repo
1. Install Airflow (the install is part of the `coder_script`)
1. Start Airflow `airflow standalone`
1. Download, install and start code-server (VS Code-in-a-browser)

### Additional step(s)
1. An Administrator password is created as part of the installation. You can retrieve it from `~/airflow/standalone_admin_password.txt` and use it with username `admin` when accessing Airflow at `http://localhost:8080`

### Known limitations
1. Coder OSS currently does not have dev URL functionality built-in, so to run Airflow, developers either use `coder port-forward <workspace name> --tcp 8080:8080` or `ssh -L 8080:localhost:8080 coder.<workspace name>`
1. Note that an `aiflow` `coder_app` is not in this template since dev URLs are needed for that to work.
1. `airflow standalone` requires `airflow` is in the `PATH` so we export `export PATH=$PATH:$HOME/.local/bin` as the start of `coder_script`

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[Airflow Concepts docs](https://airflow.apache.org/docs/apache-airflow/1.10.1/concepts.html))
