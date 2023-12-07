# v2 OSS and Enterprise FAQ

[Coder's docs](https://github.com/coder/coder/tree/main/docs) are the primary
source of truth for installing, configuring and using Coder.

But I come across commonly asked questions or tricky scenarios where these tips
may get you unstuck and help you out. Good luck! 🥳

![Rust CLion Workspace UI](./images/rust-clion-workspace.png)

<details>
    <summary>How to add an enterprise license</summary>
<br/>

Contact https://coder.com/trial or sales@coder.com to get a v2 enterprise trial key.

<br/>

You can add a license through the UI or CLI.

In the UI, click the Deployment tab -> Licenses and upload the `jwt` license file

> To add the license with the CLI, first install your Coder CLI and server to the latest release

<br/>

If the license is a text string

```sh
coder licenses add -l 1f5...765
```

If the license is in a file

```sh
coder licenses add -f <path/filename>
```

</details>

<details>
    <summary>I'm experiencing networking issues, so want to disable Tailscale, STUN, Direct connections and force use of websockets</summary>
<br/>

The primary developer IDE use case is a local IDE connecting over SSH to a Coder workspace.

Coder's networking stack has intelligence to attempt a peer-to-peer or `Direct` connection between the local IDE and the workspace, skipping routing traffic through the Coder control plane, thus reducing latency and a better developer experience.

However, this requires some additional protocols like UDP and being able to reach a STUN server to echo the IP addresses of the local IDE machine and workspace, for sharing using a Wireguard Coordination Server.

By default, Coder assumes Internet and attempts to reach Google's STUN servers to perform this IP echo.

Operators experimenting with Coder make run into networking issues if UDP (which STUN requires) or the STUN servers are unavailable, potentially resulting in lengthy local IDE and SSH connection times as the Coder control plane attempts to establish these direct connections.

A good troubleshooting tip is to just disable STUN, Direct connections, and even forcing websockets versus the embedded Tailscale DERP relay server.

<br/>

If using a `systemd` configuration of Coder's control plane, add these values to `/etc/coder.d/coder.env`:

```sh
# disable peer-to-peer, force web sockets
CODER_BLOCK_DIRECT=true
CODER_DERP_SERVER_STUN_ADDRESSES="disable"
CODER_DERP_FORCE_WEBSOCKETS=true
```

If using a Kubernetes deployment, add these values to your `values.yaml` then `helm upgrade`:

```yaml
# disable Peer-to-Peer connections (e.g., local computer with SSH, local VS Code, local JetBrains Gateway)
- name: CODER_BLOCK_DIRECT
  value: "false"
# unset Google STUN servers that are hardcoded into Coder
- name: CODER_DERP_SERVER_STUN_ADDRESSES
  value: "disable"
# force websockets
- name: CODER_DERP_FORCE_WEBSOCKETS
  value: "true"
```

If starting the coder server from the command line, set these environment variables

`coder server --block-direct-connections=true --derp-server-stun-addresses=disable --derp-force-websockets=true`

</details>

<details>
    <summary>How to configure NGINX as the reverse proxy in front of Coder</summary>
<br/>

[This doc](https://github.com/coder/coder/tree/main/examples/web-server/nginx#configure-nginx) in our repo explains in detail how to configure NGINX with Coder so that our Tailscale Wireguard networking works

</details>

<details>
    <summary>I want to hide some of the default icons in a workspace like VS Code Desktop, Terminal, SSH, Ports</summary>
<br/>

Inside the `coder_agent` block of a template, add this block and configure as needed:

```hcl
  display_apps {
    vscode = false
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = false
    web_terminal = true
  }
```

This is example will shown any other `coder_app` entries in the template, and the web terminal only.

</details>

<details>
    <summary>I want to allow code-server to be accessible by other users in my deployment</summary>
<br/>

> It is not recommended to share a web IDE, but if required, the following deployment environment variable settings are required

1. Set deployment (Kubernetes) to allow path app sharing

```yaml
# allow authenticated users to access path-based workspace apps
    - name: CODER_DANGEROUS_ALLOW_PATH_APP_SHARING
      value: "true"
# allow Coder owner roles to access path-based workspace apps
    - name: CODER_DANGEROUS_ALLOW_PATH_APP_SITE_OWNER_ACCESS
      value: "true"      
```

2. In the template, set `coder_app` `share=authenticated` and when a workspae is built with this template, the pretty globe shows up next to path-based `code-server`

KNOWN ISSUE: The first time another user authenticates to Coder with the code-server link, it gives a `404` but if you refresh, it works

</details>

<details>
    <summary>I installed Coder, created a workspace but the icons do not load</summary>
<br/>

An important concept to understand is that Coder creates workspaces which have
an agent that must be able to reach the `coder server`.

If the `CODER_ACCESS_URL` is not accessible from a workspace, the workspace may
build, but the agent cannot reach Coder, and thus the missing icons. e.g.,
Terminal, IDEs, Apps.

<br/>

> By default, `coder server` automatically creates an Internet-accessible
> reverse proxy so that workspaces you create can reach the server.

<br/>

If you are doing a standalone install, e.g., on a Macbook and want to build
workspaces in Docker Desktop, everything is self-contained and workspaces
(containers in Docker Desktop) can reach the Coder server.

```sh
coder server --access-url http://localhost:3000 --address 0.0.0.0:3000
```

> Even `coder server` which creates a reverse proxy, will let you use
> http://localhost to access Coder from a browser.

</details>

<details>
    <summary>I updated a template, and an existing workspace based on that template fails to start.</summary>
<br/>

I used to be a big fan of input variables in my templates e.g., prompt the user
to choose a [code-server](https://github.com/coder/code-server) [VS
Code](https://code.visualstudio.com/) IDE release, a [container
image](https://hub.docker.com/u/codercom), a [VS Code
extension](https://marketplace.visualstudio.com/vscode). But you have to
understand if you remove any of those values in a template, existing workspaces
that use those removed values will fail to start since the Terraform state will
not be in sync with the new template.

But there's little known CLI sub-command called `update` that will re-prompt the
user to re-enter the input variables thus saving your workspace from a failed
status.

```sh
coder update --always-prompt <workspace name>
```

</details>

<details>
    <summary>I'm running coder on a VM with systemd but latest release installed isn't showing up.</summary>
<br/>

One of my Coder deployments is a 2 shared vCPU systemd service.

When I upgrade to the latest release, you need to reload the daemon then restart
the Coder service. This ensures the `systemd` daemon does not try to reference
to previous Coder release service since the unit file has changed.

```sh
curl -fsSL https://coder.com/install.sh | sh
sudo systemctl daemon-reload
sudo systemctl restart coder.service
```

</details>

<details>
    <summary>I'm using the built-in Postgres database and forgot admin email I set up.</summary>
<br/>

1. Run the following `coder server` to retrieve the `psql` connection URL which
   includes the database user and password.
2. `psql` into Postgres, and do a select query on the `users` table.
3. Restart the `coder server`, pull up the Coder UI and log in (hope you
   remembered your password 😆)

```sh
coder server postgres-builtin-url
psql "postgres://coder@localhost:53737/coder?sslmode=disable&password=I2S...pTk"
```

</details>

<details>
    <summary>How to find out Coder's latest Terraform provider version?</summary>
<br/>

[Coder is on the HashiCorp's TerraForm
registry](https://registry.terraform.io/providers/coder/coder/latest). Check
this frequently to make sure you are on the latest version.

Sometimes you can notice the version has changed and `resource` configurations
have either been deprecated or new ones added when you get warnings or errors
creating and pushing templates.

</details>

<details>
    <summary>How can I set up TLS for my deployment and not create a signed certificate?</summary>
<br/>

Caddy is an easy-to-configure reverse proxy that also automatically creates certificates from Let's Encrypt. [Install docs here](https://caddyserver.com/docs/quick-starts/reverse-proxy) You can start Caddy as a systemd service.

The Caddyfile configuration will like this where 127.0.0.1:3000 is your `CODER_ACCESS_URL`:

```sh
coder.example.com {

	reverse_proxy 127.0.0.1:3000

	tls {
		issuer acme {
			email mark@example.com
		}
	}

}
```

</details>

<details>
    <summary>I'm using Caddy as my reverse proxy in front of Coder. How do I set up a wildcard domain for port forwarding?</summary>
<br/>

You need to give Caddy your DNS provider's credentials to create wildcard certificates. This involves building the Caddy binary [from source](https://github.com/caddyserver/caddy) with the DNS provider plugin added. e.g., [Google Cloud DNS provider here](https://github.com/caddy-dns/googleclouddns)

You will need to add Go to your host running Coder to compile Caddy. Then replace the existing Caddy binary in `usr/bin` and restart the Caddy service.

The updated Caddyfile configuration will like this:

```sh
*.coder.example.com, coder.example.com {

	reverse_proxy 127.0.0.1:3000

	tls {
		issuer acme {
			email mark@example.com
			dns googleclouddns {
				gcp_project my-gcp-project
			}
		}
	}

}
```

</details>

<details>
    <summary>Can I use local or remote Terraform Modules in Coder templates?</summary>
<br/>

One way is to reference a Terraform module from a GitHub repo to avoid duplication and then just extend it or pass template-specific parameters/resources

```hcl
# template1/main.tf
module "central-coder-module" {
  source = "github.com/yourorg/central-coder-module"
  myparam = "custom-for-template1"
}

resource "ebs_volume` `custom_template1_only_resource ` {
}
```

```hcl
# template2/main.tf
module "central-coder-module" {
  source = "github.com/yourorg/central-coder-module"
  myparam = "custom-for-template2"
  myparam2 = "bar"
}

resource "aws_instance` `custom_template2_only_resource ` {
}
```

Another way using local modules is to symlink the module directory inside the template directory and then `tar` the template.

`ln -s modules template_1/modules`
`tar -cvh -C ./template_1 | coder templates <push|create> -d - <name>`

[Issue 6117](https://github.com/coder/coder/issues/6117)
[Issue 5677](https://github.com/coder/coder/issues/5677)
[Coder docs](https://coder.com/docs/v2/latest/templates/change-management)

</details>

<details>
    <summary>Can I run Coder in an air-gapped or offline mode? (no Internet)?</summary>
<br/>

Yes, Coder can be deployed in air-gapped or offline mode.
https://coder.com/docs/v2/latest/install/offline

Our product bundles with the Terraform binary so assume access to terraform.io during installation. The docs outline rebuilding the Coder container with Terraform built-in as well as any required Terraform providers.

Direct networking from local SSH to a Coder workspace needs a STUN server. We default to Google's STUN servers. So you can either create your STUN server in your network or disable and force all traffic through the control plane's DERP proxy.

</details>

<details>
    <summary>Create a randomized computer_name for an Azure VM</summary>
<br/>

Azure VMs have a 15 character limit for the computer_name which can lead to duplicate name errors.

This code produces a hashed value that will be difficult to replicate.

```hcl
locals {
concatenated_string = "${data.coder_workspace.me.name}+${data.coder_workspace.me.owner}"
hashed_string = md5(local.concatenated_string)
truncated_hash = substr(local.hashed_string, 0, 16)
}
```

</details>

<details>
    <summary>Do you have example JetBrains Gateway templates</summary>
<br/>

JetBrains certified our plugin in August which means it is more stable.

You will see the Coder plugin in Gateway when you open it up.

It depends on how you want to manage the JetBrains IDE version, but if you are open to it being downloaded from jetbrains.com, see my example template where I specify the product code, IDE version and build number in the `coder_app` resource. This will present an icon in the workspace dashboard which when clicked, will look for a locally installed Gateway, and open it.  Alternatively, you bake the IDE into the container image and manually open Gateway (or IntelliJ which has Gateway built-in), use a session token to Coder and then open the IDE. See the links below.

https://github.com/sharkymark/v2-templates/tree/main/pod-idea-icon
https://github.com/sharkymark/v2-templates/tree/main/pod-idea

</details>

<details>
    <summary>What options do I have for adding VS Code extensions into code-server, VS Code Desktop or Microsoft's Code Server</summary>
<br/>

Coder has an open-source project called `code-marketplace` which is a private VS Code extension marketplace. There is even integration with JFrog Artifactory.

[Blog post](https://coder.com/blog/running-a-private-vs-code-extension-marketplace)
[OSS project](https://github.com/coder/code-marketplace)

[See my example template](https://github.com/sharkymark/v2-templates/blob/main/code-marketplace/main.tf#L229C1-L232C12) where in the agent resource I specify the URL and config environment variables which code-server picks up and points the developer to.

image.png


Another option is to use Microsoft's code-server - which is like Coder's, but legally it can connect to Microsoft's extension marketplace so Copilot and chat can be retrieved there. [See a sample template here](https://github.com/sharkymark/v2-templates/blob/main/vs-code-server/main.tf).

Another option is to use VS Code Desktop (local) and that connects to Microsoft's marketplace.
https://github.com/sharkymark/v2-templates/blob/main/vs-code-server/main.tf

Again, these are example templates with no SLAs on them.  It's your responsibility to author your own templates.

</details>

<details>
    <summary>I want to run Docker for my workspaces but not install Docker Desktop</summary>
<br/>

[Colima](https://github.com/abiosoft/colima) is a Docker Desktop alternative. 

My example is meant for a Macbook where a user wants to try out Coder and see how it works.

1. Install colima and docker

```sh
brew install colima
brew install docker
```

2. Start colima

`colima start`

If want to specify compute options

`colima start --cpu 4 --memory 8`

starting colima on a m3 macbook pro 

`colima start --arch x86_64  --cpu 4 --memory 8 --disk 10`

colima will show the path to the docker socket so I have a [Coder template](./docker-code-server/main.tf) that prompts the Coder admin to enter the docker socket as a Terraform variable.

</details>


<details>
    <summary>Can I?</summary>
<br/>



</details>
