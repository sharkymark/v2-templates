---
name: Develop in Linux on Azure
description: Get started with Linux development on Microsoft Azure.
tags: [cloud, azure, linux]
---

# azure-linux

This template includes:
1. `code-server` IDE (VS Code in a browser)
1. Prompts the user for a dotfiles repo and clones it

## Authentication

This template assumes that coderd is run in an environment that is authenticated
with Azure. For example, run `az login` then `az account set
--subscription=<id>` or if no subscriptions, run `az login
--allow-no-subscriptions` to import credentials on the system and user running
coderd.  For other ways to authenticate [consult the Terraform
docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure).
