---
name: Develop in a container in a Kubernetes pod with optional Coder or Microsoft code-server
description: The goal is to let the user decide if they want Coder or Microsoft code-server (VS Code in a browser) 
tags: [cloud, kubernetes]
---

# Optional Coder or Microsoft code-server (VS Code) template for a workspace in a Kubernetes pod

### Apps included
1. A web-based terminal
1. Make it optional to use Coder or Microsoft's VS Code IDE in a browwser

### Additional input variables and bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for compute options (CPU core, memory, and disk)
1. Prompt user for container image to use
1. Prompt user for repo to clone
1. Clone source code repo
1. If selected, download, install and start latest code-server from Microsoft or Coder (VS Code-in-a-browser)
1. Add the Access URL and user's Coder session token in the workspace to use the Coder CLI

### Images/languages to choose from
1. NodeJS
1. Golang
1. Java
1. Base (for Rust and Python)

### IDE use
1. While the purpose of this template is let a user decide if they want to show `code-server` and VS Code in a browser, you can also use the `VS Code Desktop` to download Coder's VS Code extension and the Coder CLI to remotely connect to your Coder workspace from your local installation of VS Code.
1. The template `startup_script` conditionally installs code-server if requested

```sh
# install and Coder or Microsoft's code-server, VS Code in a browser 

BOLD='\033[0;1m'

if [ ${data.coder_parameter.code_server.value} = "cs" ]; then
  printf "$${BOLD} 🧑🏼‍💻 Downloading and installing the Coder's latest code-server IDE...\n"
  curl -fsSL https://code-server.dev/install.sh | sh
  code-server --auth none --port 13337 >/dev/null 2>&1 &
elif [ ${data.coder_parameter.code_server.value} = "vscs" ]; then

  # Create install directory if it doesn't exist
  mkdir -p ${local.vscs_install_location}

  printf "$${BOLD}Installing Microsoft's vscode-cli!\n"

  # Download and extract code-cli tarball
  output=$(curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz && tar -xf vscode_cli.tar.gz -C ${local.vscs_install_location} && rm vscode_cli.tar.gz)

  if [ $? -ne 0 ]; then
    echo "Failed to install vscode-cli: $output"
    exit 1
  fi
  printf "🥳 vscode-cli has been installed.\n\n"

  echo "🧑🏼‍💻 Running ${local.vscs_install_location}/bin/code serve-web --port ${local.cs_port} --without-connection-token --accept-server-license-terms in the background..."
  echo "Check logs at ${local.cs_log_path}!"
  ${local.vscs_install_location}/code serve-web --port ${local.cs_port} --without-connection-token --accept-server-license-terms --extensions-dir /home/coder/.vscode-server/extensions --log debug >${local.cs_log_path} 2>&1 &

else
  printf "⛔️ VS Code in a browser will not be installed.\n\n"
fi
```

1. The template uses a Terraform meta-argument in the `coder_app` resource to decide if the resource should be created if the user asked for one.

```hcl
# code-server
resource "coder_app" "code-server" {
  count        = data.coder_parameter.code_server.value != "nocs" ? 1 : 0
  agent_id      = coder_agent.coder.id
  slug          = "code-server"  
  display_name  = "code-server"
  icon          = "/icon/code.svg"
  url           = "http://localhost:${local.cs_port}?folder=/home/coder"
  subdomain = data.coder_parameter.code_server.value == "cs" ? "false" : "true"
  share     = "owner"

  healthcheck {
    url       = "http://localhost:${local.cs_port}/healthz"
    interval  = 3
    threshold = 10
  }  
}
```

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

Alternatively, the managed  terraform variables can be specified in the template UI

### Coder session token and Access URL injection

Within the agent resource's `startup_script`:

```hcl
coder login ${data.coder_workspace.me.access_url} --token ${data.coder_workspace.me.owner_session_token}
```
### Authentication

This template will use ~/.kube/config or if the control plane's service account token to authenticate to a Kubernetes cluster

Be sure to specify the workspaces_namespace variable during workspace creation to the Kubernetes namespace the workspace will be deployed to

### Resources
[Coder's Terraform Provider - parameters](https://registry.terraform.io/providers/coder/coder/latest/docs/data-sources/parameter)

[Terraform explanation of count meta-argument](https://developer.hashicorp.com/terraform/language/meta-arguments/count)

[NodeJS coder-react repo](https://github.com/mark-theshark/coder-react)

[Coder's GoLang v2 repo](https://github.com/coder/coder)

[Coder's code-server TypeScript repo](https://github.com/coder/code-server)

[Golang command line repo](https://github.com/sharkymark/commissions)

[Java Hello World repo](https://github.com/sharkymark/java_helloworld)

[Rust repo](https://github.com/sharkymark/rust-hw)

[Python repo](https://github.com/sharkymark/python_commissions)

