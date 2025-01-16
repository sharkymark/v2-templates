---
name: K8s template injecting host, ca cert and service account token
description: Use a Kubernetes cluster outside of the Coder control plane to create a pod workspace
tags: [cloud, kubernetes]
---

# Kubernetes pod on a cluster outside of Coder

### Apps included
1. A web-based terminal
1. Node.JS and React

### Template Admin inputs for remote K8s cluster
1. namespace
1. host
1. CA certificate
1. service account token

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Clone Node.jS React repo

### Kubernetes commands to retrieve host, CA cert, token

## Cluster host

```sh
kubectl cluster-info
```

## Create service account in remote Kubernetes cluster

Substitute namespace in `your_namespace`

```sh
kubectl apply -n your_namespace -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: coder
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: your_namespace
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

## Retrieve CA certificate and service account token

Substitute namespace in `your_namespace`

```sh
kubectl get secrets -n your_namespace -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='coder')].data}{'\n'}"
```

### Resources

[Node React repo](https://github.com/sharkymark/coder-react)

[Terraform Kubernetes provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)