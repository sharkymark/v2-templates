---
name: Develop with Apache Guacamole in a Kubernetes pod
description: The goal is to enable 2 containers, Guacamole client and server, and TigerVNC and XFCE in a 3rd container - in a K8s pod 
tags: [cloud, kubernetes]
---

# Apache Guacamole, TigerVNC & XFCE in a Kubernetes pod

### Key points
1. `coder_agent` is only for the `base-container` that has TigerVNC Server
1. A custom Guacamole client image is needed to copy the config files `guacamole.properties` and `user-mapping.xml`

https://tigervnc.org/

### Apps included
1. A web-based terminal
1. code-server (VS Code Web)
1. Apache Guacamole, a clientless remote desktop gateway
1. TigerVNC Srever, a high-performance, platform-neutral implementation of VNC (Virtual Network Computing), a client/server application that allows users to launch and interact with graphical applications on remote machines. 
1. XFCE, a lightweight desktop environment for UNIX-like operating systems

### Images for the 3 containers
1. [Custom Guacamole Client Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/guacamole/client) and [Image on DockerHub](https://hub.docker.com/repository/docker/marktmilligan/guacamole/general) as user `1001`
2. [Guacamole Server](https://hub.docker.com/r/guacamole/guacd) as user `1000`
3. [Custom TigerVNC Server Dockerfile](https://github.com/sharkymark/dockerfiles/tree/main/tiger-vnc) and [Image on DockerHub](https://hub.docker.com/repository/docker/marktmilligan/tigervnc/general) as user `1000`

### Additional bash scripting
1. Prompt user and clone/install a dotfiles repository (for personalization settings)

### defaults
1. (Guacamole) Username: coder Password: password (see in `user-mapping.xml`) 
2. Authentication to TigerVNC is disabled in `supervisord.conf` with `command=vncserver :1 -SecurityTypes None`

### Known issues
1. XFCE has a screen lock built-in (called `light-locker`) that locks the Linux desktop in 10 minutes. Given this is browser-enabled with Guacamole, the keyboard command to unlock does not work. For the meantime, go into Applications/Settings/Power and disable screensaver and light-locker. 

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

[TigerVNC docs](https://manpages.ubuntu.com/manpages/bionic/man1/tigervncserver.1.html)

[XFCE](https://www.xfce.org/)

[TigreVNC](https://tigervnc.org/)

[Remove `light-locker` screen lock](https://askubuntu.com/questions/1169604/how-to-disable-light-locker-in-xubuntu-14-04-via-command-line)

[Apache Guacamole](https://guacamole.apache.org/)

### What's next?

Goal is to apply this to a Microsoft Windows and Visual Studio 2022 VM workspace
