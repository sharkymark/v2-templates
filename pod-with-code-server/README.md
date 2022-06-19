---
name: Develop in a container in a Kubernetes pod with a code-server IDE
description: The goal is to enable code-server (VS Code)
tags: [cloud, kubernetes]
---

# Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to change the workspaces_namespace variable to the Kubernetes namespace the workspace will be deployed to
