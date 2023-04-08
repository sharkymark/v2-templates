---
name: Use your GitHub Oauth token to authenticate a git operation
description: The goal is to show how to use your GitHub Oauth token to authenticate a git operation, in a Docker container
tags: [local, docker]
---

# Simple container in Docker to use authenticate git actions with OAuth

### Apps included

1. A web-based terminal
1. code-server IDE (VS Code Web)

### Additional bash scripting

1. `git clone` a dotfiles or personalize repo

### GitHub OAuth Admin Setup

1. Create an OAuth app in GitHub with correct URL and Callback URLs to your Coder deployment

2. K8s `values.yaml` example

```sh
# enable OAuth git authentication for git actions
    - name: CODER_GITAUTH_0_ID
      value: "primary-github"

    - name: CODER_GITAUTH_0_TYPE
      value: "github"

    - name: CODER_GITAUTH_0_CLIENT_ID
      value: "ed21c3********3bec7f"

    - name: CODER_GITAUTH_0_CLIENT_SECRET
      value: "299417626a5d48*******ba6dea0868c356e"
```

3. `systemd` example

```sh
CODER_GITAUTH_0_ID="primary-github"
CODER_GITAUTH_0_TYPE=github
CODER_GITAUTH_0_CLIENT_ID=b9684*********a7d03
CODER_GITAUTH_0_CLIENT_SECRET=4b00110dda08f8************c0385df092faec6b4
```

### GitHub OAuth Template Sections

1. Parameter to receive repo from user input at workspace creation

```hcl
data "coder_parameter" "personalize_url" {
  name        = "Personalize URL"
  description = "Personalize your workspace with a personalize repo script or Dotfiles repo - using your GitHub OAuth token"
  type        = "string"
  default     = "https://github.com/.../dotfiles.git"
  mutable     = true
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}
```

2. Coder provider git auth data source

> `id` was configured in the Coder Admin setup

```hcl
data "coder_git_auth" "github" {
  # Matches the ID of the git auth provider in Coder.
  id = "primary-github"
}
```

3. `coder_agent` environment variable setting and `git clone` in `startup_script`

```hcl
resource "coder_agent" "dev" {...

  env = {
    GITHUB_TOKEN : data.coder_git_auth.github.access_token
  }

  startup_script  = <<EOT
#!/bin/bash

# clone dotfiles
git clone ${data.coder_parameter.personalize_url.value}
```

### CPU shares

`cpu_shares` This is the relavent weight for scheduling CPU time for containers on the Docker host. i.e., The Docker host has a specified amount of CPUs available. The `cpu_shares` is the portion of that for accessing the available CPUs.

e.g., Setting one container’s cpu_share to 512 and another container’s to 1024 means that the second container will get double the amount of CPU time as the first. If the Docker host has 1 CPU, then the first container will `.5` CPU and the 2nd container will get `.25` CPU.

### Memory

The memory limit `memory` for the container in MB per the Terraform provider.

### Storage

Key/value pair for the storage driver options.

Commented out.

This option is only available for the devicemapper, btrfs, overlay2, windowsfilter and zfs graph drivers. For the devicemapper, btrfs, windowsfilter and zfs graph drivers, user cannot pass a size less than the Default BaseFS Size. For the overlay2 storage driver, the size option is only available if the backing fs is xfs and mounted with the pquota mount option. Under these conditions, user can pass any size less then the backing fs size.

### Resources

[Coder provider Git Auth docs](https://registry.terraform.io/providers/coder/coder/latest/docs/data-sources/git_auth)

[Coder docs to configure Git Auth](https://coder.com/docs/v2/latest/admin/git-providers)

[GitHub docs for creating an OAuth app](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app)

[CPU share description](https://www.batey.info/cgroup-cpu-shares-for-docker.html)

[Memory description](https://docs.docker.com/config/containers/resource_constraints/)

[Storage description](https://docs.docker.com/storage/#:~:text=Docker%20has%20two%20options%20for,memory%20on%20the%20host%20machine.)

[Terraform kreuzwerker Docker provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container)
