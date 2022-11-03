---
name: Port forward a process and access in the Dashboard from a container in a Docker host with code-server
description: The goal is to port forward a `coder_app` specified in the workspace template 
tags: [local, docker]
---

# Port forward a process in a workspace in a container on a Docker host

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)
1. A `coder_app` in the template to port forward a Node React app

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Clone repo
1. `yarn` the repo to build dependencies
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. You must first open a web terminal, cd into the `coder-react` repo directory and start the process with `yarn start` for the port forward icon to successfully pass the health check.

### Authentication
1. The `coder_app` specifies the port forwarded process is accessible to anyone authenticated to the Coder deployment. See the configuration:

```hcl
subdomain = true
share     = "authenticated"
```

### Resources
[coder-react repo](https://github.com/sharkymark/coder-react)
[port forwarding docs](https://coder.com/docs/coder-oss/latest/networking/port-forwarding#examples)
