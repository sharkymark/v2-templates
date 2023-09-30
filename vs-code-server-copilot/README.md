---
name: Develop in a container in a Kubernetes pod with Microsoft Visual Studio Code Server
description: The goal is to enable Microsoft Visual Studio Code Server (VS Code in a browser) 
tags: [cloud, kubernetes]
---

# Microsoft Visual Studio Code Server template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. Microsoft Visual Studio Code Server IDE

### Additional input variables and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Clone source code repo
1. Download, install and start latest Microsoft Visual Studio Code Server

### Images/languages to choose from
1. NodeJS
1. Golang
1. Java
1. Base (for Rust and Python)

> Note that Rust is installed during the startup script for `~/` configuration
   
### Parameters
Parameters allow users who create workspaces to additional information required in the workspace build. This template will prompt the user for:
1. A Dotfiles repository for workspace personalization `data "coder_parameter" "dotfiles_url"`
2. The size of the persistent volume claim or `/home/coder` directory `data "coder_parameter" "pvc"`

### Managed Terraform variables
Managed Terraform variables can be freely managed by the template author to build templates. Workspace users are not able to modify template variables. This template has two managed Terraform variables:
1. `use_kubeconfig` which tells Coder which cluster and where to get the Kubernetes service account
2. `workspaces_namespace` which tells Coder which namespace to create the workspace pdo

Managed terraform variables are set in coder templates create & coder templates push.

`coder templates create --variable workspaces_namespace='my-namespace' --variable use_kubeconfig=true --default-ttl 2h -y`

`coder templates push --variable workspaces_namespace='my-namespace' --variable use_kubeconfig=true  -y`

Alternatively, the managed terraform variables can be specified in the template UI

### Microsoft Visual Studio Code Server

> Microsoft has changed how to run Visual Studio Code Server remotely a couple times in 2023

1. Install packages required by Microsoft Visual Studio Code

```sh
# install OS packages expected by microsoft visual studio code

sudo apt update -y
sudo apt install -y libnss3 libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 libcairo2 libdrm2 libgbm1 libgtk-3-0 libnspr4 libpango-1.0-0 libsecret-1-0 libxcomposite1 libxdamage1 libxfixes3 libxkbcommon0 libxkbfile1 libxrandr2 xdg-utils
```

2. Download and start the IDE in the `startup_script`:

```sh
# install microsoft visual studio code server

curl -L "https://update.code.visualstudio.com/1.82.2/linux-deb-x64/stable" -o /tmp/code.deb
sudo dpkg -i /tmp/code.deb && sudo apt-get install -f -y

code serve-web --port 13338 --without-connection-token --accept-server-license-terms >/tmp/vscode-web.log 2>&1 &
```

3. Auto install GitHub Copilot VS Code extension

```sh
# install github.copilot & github.copilot-chat - note setting the extensions directory under .vscode-server
code --extensions-dir=/home/coder/.vscode-server/extensions --install-extension github.copilot &
```

4. Configure a `coder_app` block for the IDE

```hcl
# microsoft vs code server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  slug          = "code-server"  
  display_name  = "Visual Studio Code Server"
  icon          = "/icon/code.svg"
  url           = "http://localhost:13338?folder=/home/coder"
  subdomain = true
  share     = "owner"

  healthcheck {
    url       = "http://localhost:13338/healthz"
    interval  = 3
    threshold = 10
  }  
}
```

### GitHub Copilot example

1. Open Microsoft Visual Studio Code Server 

2. Create a new JavaScript file called `foo.js`

3. Paste the following function header:

```javascript
function calculateDaysBetweenDates(begin, end) {
```

4. Copilot will recommend code in the function, and press tab to accept the suggested code. On Mac, press `Option + ]` to see the next suggestion

5. Have Copilot suggest code from comments

```javascript
// find all images without alternate text
// and give them a red border
function process() {

```

6. Create a Python3 web server

```
// python3 web server 
```
### Authentication

This template will use ~/.kube/config or if the control plane's service account token to authenticate to a Kubernetes cluster

Be sure to specify the workspaces_namespace variable during workspace creation to the Kubernetes namespace the workspace will be deployed to

### Resources
[Coder's Terraform Provider - parameters](https://registry.terraform.io/providers/coder/coder/latest/docs/data-sources/parameter)

[Microsoft VS Code Server home page](https://code.visualstudio.com/docs/remote/vscode-server)

[GitHub Copilot](https://github.com/features/copilot)

[GitHub Copilot Example Suggestions](https://docs.github.com/en/copilot/getting-started-with-github-copilot?tool=vscode)

[NodeJS coder-react repo](https://github.com/mark-theshark/coder-react)

[Coder's GoLang v2 repo](https://github.com/coder/coder)

[Coder's code-server TypeScript repo](https://github.com/coder/code-server)

[Golang command line repo](https://github.com/sharkymark/commissions)

[Java Hello World repo](https://github.com/sharkymark/java_helloworld)

[Rust repo](https://github.com/sharkymark/rust-hw)

[Python repo](https://github.com/sharkymark/python_commissions)

