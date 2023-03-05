---
name: Develop with Apache Guacamole in a Kubernetes pod
description: The goal is to enable 2 containers, Guacamole client and server in a K8s pod 
tags: [cloud, kubernetes]
---

# Apache Guacamole in a Kubernetes pod

### DO NOT USE - WORK IN PROGRESS

### Outstanding To-Do's
1. Figure out how to get user-mapping.xml into the workspace
2. Figure out how to properly change the location of $GUACAMOLE_HOME to the `/home/coder` PVC
3. Start either a Tiger VNC server or an RDP server to test (since if I manually copy `user-mapping.xml` to $GUACAMOLE_HOME, I am able to auth into the Guacamole client and make the connection to the Guacamole server, but from there, to either VNC or RDP, connection is refused - which makes sense, since I do not have either server running)
4. Idea: Add a 4th container for the RDP or Tiger VNC server

https://tigervnc.org/

### Apps included
1. A web-based terminal
1. code-server (VS Code Web)
1. Guacamole VNC UI

### Images for the 2 containers
1. [Guacamole Client](https://hub.docker.com/r/guacamole/guacd)
2. [Guacamole Server](https://hub.docker.com/r/guacamole/guacamole)

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)

### defaults
1. (Guacamole) Username: guacadmin Password: guacadmin 

### Authentication

This template will use ~/.kube/config to authenticate to a Kubernetes cluster on GCP

Be sure to enter a valid workspaces_namespace at workspace creation to point to the Kubernetes namespace the workspace will be deployed to

### Resources
[Guacamole config docs](https://guacamole.apache.org/doc/gug/configuring-guacamole.html)

[Guac Docker images example](https://kifarunix.com/install-apache-guacamole-as-docker-container-on-ubuntu/)

[Guacamole client Dockerfile](https://github.com/apache/guacamole-client/blob/master/Dockerfile)

[Guacammole server Dockerfile](https://github.com/apache/guacamole-server/blob/master/Dockerfile)

[Guacamole troubleshooting](https://guacamole.apache.org/doc/gug/troubleshooting.html)

[Gucamole docs on VNC](https://guacamole.apache.org/doc/gug/configuring-guacamole.html#vnc)

### Notes

Copy user-mapping.xml to guac client container manually
```sh
kubectl cp ./user-mapping.xml coder-mark-guac:/home/guacamole/.guacamole/user-mapping.xml -c guac-client-container -n coder
```

Error trying to connect with VNC (from guacd server logs)
```sh
guacd[1]: INFO:	Creating new client for protocol "vnc"
guacd[1]: INFO:	Connection ID is "$76d4876b-22de-4000-b81a-747f2e9904df"
guacd[8]: INFO:	Cursor rendering: local
guacd[8]: INFO:	User "@963039b6-a85a-4f8b-aa18-4b504cfbe3b8" joined connection "$76d4876b-22de-4000-b81a-747f2e9904df" (1 users now present)
guacd[8]: ERROR:	Unable to connect to VNC server.
guacd[8]: INFO:	User "@963039b6-a85a-4f8b-aa18-4b504cfbe3b8" disconnected (0 users remain)
guacd[8]: INFO:	Last user of connection "$76d4876b-22de-4000-b81a-747f2e9904df" disconnected
guacd[1]: INFO:	Connection "$76d4876b-22de-4000-b81a-747f2e9904df" removed.
```

