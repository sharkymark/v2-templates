---
name: Develop in a container with pgAdmin in a Kubernetes pod
description: The goal is to enable pgAdmin in a container to access external Postgres databases
tags: [cloud, kubernetes]
---

# pgAdmin template as a Kubernetes-managed container

### Apps included

1. A web-based terminal
1. code-server `coder_app`
1. pgAdmin `coder_app`

### Additional bash scripting

1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Download and install `code-server` IDE
1. Download and install `pgAdmin` RDBMS tool

### Known problems
1. `coder_app` of pgAdmin does not work - since the URL redirects
1. Open port `80` and append `/pgadmin4` to the URL and pgAdmin should open

### Authentication

This template will use a service account to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable in the template creation to the Kubernetes namespace the workspace will be deployed to

### Resources

[pgAdmin Ubuntu docs](https://www.pgadmin.org/download/pgadmin-4-apt/)
