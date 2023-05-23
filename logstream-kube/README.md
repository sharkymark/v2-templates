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

This template passes Terraform variables at template creation for:

1. `host` obtained with `kubectl cluster-info`
2. service account `ca cert` and `token` obtained with `kubectl get secrets -n <your namespace> -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='coder')].data}{'\n'}"`

The coder service account does not have deployment permissions so a role and rolebinding to the coder service account are required:

```sh
kubectl create clusterrole deployer --verb=get,list,watch,create,delete,patch,update --resource=deployments.apps --namespace=<your namespace>
kubectl create clusterrolebinding deployer-srvacct-default-binding --clusterrole=deployer --namespace=<your namespace> --serviceaccount=<your namespace>:coder
```

Alternatively, you can create a new service account for the namespace:

```yaml
kubectl apply -n <your namespace> -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: coder
---
apiVersion: v1
kind: Secret
metadata:
  name: coder-service-account-token
  annotations:
    kubernetes.io/service-account.name: coder
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: coder
rules:
  - apiGroups: ["", "apps", "networking.k8s.io"] # "" indicates the core API group
    resources: ["persistentvolumeclaims", "pods", "deployments", "services", "secrets", "pods/exec","pods/log", "events", "networkpolicies", "serviceaccounts"]
    verbs: ["create", "get", "list", "watch", "update", "patch", "delete", "deletecollection"]
  - apiGroups: ["metrics.k8s.io", "storage.k8s.io"]
    resources: ["pods", "storageclasses"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: coder
subjects:
  - kind: ServiceAccount
    name: coder
roleRef:
  kind: Role
  name: coder
  apiGroup: rbac.authorization.k8s.io
EOF
```

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
