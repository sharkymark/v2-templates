---
name: Prompt user for Linux shell to enable
description: The goal is to show how a template can enable a shell for a Docker-based container workspace
tags: [local, docker]
---

# Simple container where a user can specify which shell to enable

### Apps included

1. A web-based terminal
1. code-server IDE (VS Code Web)

### Additional bash scripting

1. Prompt user for shell to use
1. Download, install and start code-server (VS Code-in-a-browser)

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

[zsh shell](https://en.wikipedia.org/wiki/Z_shell)

[fish shell](https://fishshell.com/)

[CPU share description](https://www.batey.info/cgroup-cpu-shares-for-docker.html)

[Memory description](https://docs.docker.com/config/containers/resource_constraints/)

[Storage description](https://docs.docker.com/storage/#:~:text=Docker%20has%20two%20options%20for,memory%20on%20the%20host%20machine.)

[Terraform kreuzwerker Docker provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/container)
