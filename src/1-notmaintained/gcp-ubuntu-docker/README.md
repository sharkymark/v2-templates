---
name: Develop in Linux on Google Cloud
description: Get started with Linux development on Google Cloud.
tags: [cloud, google]
---

# GCP Linux VM with Docker engine template

### Apps included
1. A web-based terminal
1. code-server IDE (VS Code-in-a-browser)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Prompt user for GCP project to provision the workspace on (consider hard-coding this)
1. Select GCP zone
1. Download, install and start code-server (VS Code-in-a-browser)

### Known limitations
1. If you fat finger the GCP project (and it doesn't match what was entered during template creation, it bricks a workspace, with no VM created and no way to delete it)
1. Coder OSS does not do a health check if the IDE and coder-script have successfully run, so opening terminal and code-server may lead to failures. Wait a few minutes for everything to run.

### Resources
[GCP Regions and Zones](https://cloud.google.com/compute/docs/regions-zones)

[GCP Projects docs](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
