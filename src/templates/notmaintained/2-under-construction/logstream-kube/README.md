---
name: Kubernetes workspace logging
description: Stream Kubernetes logs into a Coder workspace.
tags: [cloud, kubernetes]
icon: /icon/k8s.png
---

# Kubernetes logging in the workspace UI

This template creates a deployment running the `codercom/enterprise-base:ubuntu` image.

A `coder-logstream-kube` pod is already running and will stream Kubernetes logs into the workspace UI logs.

The business value is faster troubleshooting and better information to the developer or data scientist using Coder, if they experience challenges with their Coder workspace.

## Kubernetes prerequisite

The workspace must be a deployment and not a pod resource in Terraform

## Authentication

This template prompts the template administrator for the cluster namespace and whether to use the `.kube/config` on the host (true) or the Coder control plane's service account (false)

## code-server

`code-server` is installed via the `startup_script` argument in the `coder_agent`
resource block. The `coder_app` resource is defined to access `code-server` through
the dashboard UI over `localhost:13337`.

## Resources

[coder-logstream-kube](https://github.com/coder/coder-logstream-kube)

[Kubernetes deployment Terraform provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment)

[Coder Terraform provider](https://registry.terraform.io/providers/coder/coder/latest/docs)

[Kubernetes authentication options Terraform](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)

[Kubernetes roles and rolebindings](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
