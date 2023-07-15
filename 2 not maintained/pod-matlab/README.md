---
name: Develop with MATLAB in a container in a Kubernetes pod
description: The goal is to enable code-server (VS Code) and MATLAB
tags: [cloud, kubernetes]
---

# MATLAB IDE and code-server (VS Code) template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. MATLAB IDE

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Start MATLAB (it is installed as part of the image)
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations


### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to

### Resources
[MATLAB releases](https://hub.docker.com/r/mathworks/matlab)

[MATLAB Proxy](https://github.com/mathworks/matlab-proxy)

[MATLAB Proxy Advanced Usage - CLI](https://github.com/mathworks/matlab-proxy/blob/main/Advanced-Usage.md)

[MATLAB docs for container on DockerHub](https://www.mathworks.com/help/cloudcenter/ug/matlab-container-on-docker-hub.html)

[MATLAB Trial License Signup](https://www.mathworks.com/campaigns/products/trials.html)