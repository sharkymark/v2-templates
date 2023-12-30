---
name: Develop with JetBrains IntelliJ IDEA Ultimate in a Kubernetes pod
description: The goal is to enable a dashboard icon to an IntelliJ IDEA Ultimate container that JetBrains Gateway can connect to 
tags: [cloud, kubernetes]
---

# Launch an IntelliJ IDEA Ultimate IDE from a dashboard icon

IntelliJ is launched from a locally-installed JetBrains Gateway client connected to a Coder Cloud Development Environment operating as Kubernetes-managed container with a mounted persistent disk to store personal settings and cloned code repositories. 

### Cloud Cost Control Use Case
1. The templates [establish costs](https://coder.com/docs/v2/latest/admin/quotas#establishing-costs) for compute resources of a workspace. e.g., Kubernetes pod = `20` points and a persistent disk = `10` points. 
2. A group [establishes a budget](https://coder.com/docs/v2/latest/admin/quotas#establishing-budgets) to restrict how many compute resources a developer can use. e.g., `60` points which would allow 2 running workspaces. If the user attempts to create a 3rd, the build will fail and the user notified.
3. This is an Enterprise feature that requires a paid license [Contact Sales](https://coder.com/contact) for more information.

### User inputs

1. The size of the persistent disk `/home/coder` - default 30GB. Range 10-100GB. The disk size cannot be reduced.

### Apps included
1. A web-based terminal
1. JetBrains IDE launched from a dashboard icon (accessible with SSH and JetBrains Gateway)

### IntelliJ IDEA version

Last updated at: 2023-12-30

ide_product_code = `IU` 
ide_build_number = `233.13135.65`   
ide = `ideaIU-2023.3.2`

#### Reference

[jetbrains product codes](https://plugins.jetbrains.com/docs/marketplace/product-codes.html)

[ide build numbers](https://www.jetbrains.com/idea/download/other.html)

[ide release downloads](https://data.services.jetbrains.com/products/releases?code=IU)

### Launching JetBrains Gateway and IntelliJ from a workspace dashboard icon

You must define `coder_app` resource using `external = true` and specific `url` string and format that includes JetBrains-specific information such as`ide_product_code`, `ide_build_number` and `ide_download_link`

The build number tells Gateway which JetBrains client to download to the developer's local machine.

The IDE download link tells Gateway which IDE to download into the Coder workspace.

```hcl
resource "coder_app" "gateway" {
  agent_id     = coder_agent.coder.id
  display_name = "IntelliJ Ultimate"
  slug         = "gateway"
  url          = "jetbrains-gateway://connect#type=coder&workspace=${data.coder_workspace.me.name}&agent=coder&folder=/home/coder/&url=${data.coder_workspace.me.access_url}&token=${data.coder_workspace.me.owner_session_token}&ide_product_code=${local.ide_product_code}&ide_build_number=${local.ide_build_number}&ide_download_link=${local.ide_download_link}"
  icon         = "/icon/intellij.svg"
  external     = true
}
```


### JetBrains IDE images to choose from

Last updated at: 2023-12-30

Switched from Coder deprecated image to custom image

[IntelliJ IDEA Ultimate](https://www.jetbrains.com/idea/download/)

[marktmilligan/java:jdk-11 Dockerfile](https://github.com/sharkymark/dockerfiles/blob/main/java/Dockerfile)

[marktmilligan/java container image](https://hub.docker.com/repository/docker/marktmilligan/java/tags)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Configure pod spec to use the Docker image specific to the IDE

### Post Build Requisites
1. Install and configure [JetBrains Gateway](https://coder.com/docs/v2/latest/ides/gateway)

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to enter a valid workspaces_namespace at workspace creation to point to the Kubernetes namespace the workspace will be deployed to

### Resources
[JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/)

[Coder Gateway docs](https://coder.com/docs/v2/latest/ides/gateway)

[Gateway docs](https://www.jetbrains.com/help/idea/remote-development-a.html#gateway)

[Gateway offline mode docs](https://www.jetbrains.com/help/idea/fully-offline-mode.html)

[Gateway Issue Tracker](https://youtrack.jetbrains.com/issues/CWM?_ga=2.95348572.1706460293.1667768201-1827063151.1646598008&_gl=1*jrexxd*_ga*MTgyNzA2MzE1MS4xNjQ2NTk4MDA4*_ga_9J976DJZ68*MTY2NzkxMTA1Mi4xOC4xLjE2Njc5MTE1MDUuMC4wLjA.)

[JetBrains product codes - 2 letters](https://plugins.jetbrains.com/docs/marketplace/product-codes.html     )

[JetBrains IDE versions and builds](https://www.jetbrains.com/idea/download/other.html)

[JetBrains IDE download links](https://data.services.jetbrains.com/products/releases?code=IU)