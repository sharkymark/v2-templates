---
name: Develop with KasmVNC & an Eclipse IDE in a Kubernetes pod
description: The goal is to enable an KasmVNC & an Eclipse IDE container for a browser experience
tags: [cloud, kubernetes]
---

# KasmVNC & an Eclipse IDE template for a workspace in a Kubernetes pod

### Apps included

1. A web-based terminal
1. An Eclipse IDE IDE (accessible with VNC)

### Eclipse IDE image

1. [Eclipse releases](https://download.eclipse.org/eclipse/downloads/) [KasmVNC and Eclipse Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/eclipse/kasm))

> Click on Linux x86_64 link, then right-click the download link and copy it for the wget url needed. It includes the mirror, add &r=1 after mirror

### Additional bash scripting

1. Start KasmVNC scripts
1. Prompt user and clone/install a dotfiles repository (for personalization settings)
1. Clone [marktmilligan/hello_javaworld](https://github.com/sharkymark/java_helloworld) repo
1. Start Eclipse IDE

### Starting KasmVNC

```sh
echo "starting KasmVNC"
/dockerstartup/kasm_default_profile.sh
/dockerstartup/vnc_startup.sh &
```

### Starting Eclipse IDE

```sh
echo "starting Eclipse IDE"
/opt/eclipse/eclipse &
```

### Known issues

1. The image is based on the KasmVNC Desktop image so the user is `kasm-user` which is used for the PVC and storage agent metadata

### Why this template?

1. Some enterprises still do a lot of Eclipse Java development and Eclipse is not a browser-native IDE

### Authentication

This template will use ~/.kube/config or control plane's service account to authenticate to a Kubernetes cluster and provision the workspace pod

Be sure an admin enters a valid workspaces_namespace in the locals section of the template to point to the Kubernetes namespace the workspace will be deployed to

### Resources

[KasmVNC and Eclipse Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/eclipse/kasm)

[sameple Java repo: hello_javaworld](https://github.com/sharkymark/java_helloworld)

[Eclipse releases](https://download.eclipse.org/eclipse/downloads/)

[KasmVNC home page](https://www.kasmweb.com/kasmvnc)

[KasmVNC repository](https://github.com/kasmtech/KasmVNC)
