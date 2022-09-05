---
name: Coder OSS (v2) FAQ
description: FAQ using Coder OSS (v2)
tags: [FAQ, v2]
---

# Coder OSS FAQ
- [Agent in UI in connecting status](#connecting-status)
- [How to run coder on my laptop but build workspaces in Google Cloud](#how-to-run-coder-on-my-laptop-but-build-workspaces-in-google-cloud)
- [Error pinging Docker server: Got permission denied](#error-pinging-docker-server-got-permission-denied)

# Agent in UI in connecting status
A common cause for this state is that your workspace cannot communicate with the coder server because the CODER_ACCESS_URL is incorrectly set.

It needs to be a public DNS entry or IP address that the workspace in DO can reach.

Another cause can be you configured TLS but the access url still has http and not changed to https

# How to run coder on my laptop but build workspaces in Google Cloud
`coder server tunnel` from your laptop creates a public access url to open coder in a browser. It also lets GCP workspaces to reach your laptop.

Depending on the template you use, Coder will leverage the Google Cloud CLI on your machine and the credentials to build a VM workspace.

After starting Coder, open another terminal and coder login with the tunnel access URL that you see in the server logs.

Then run `coder templates init` and choose one of the GCP example templates and coder templates create to create the template in the coder server.

At that point, you can use the UI to create a workspace from that template.

Our GCP ones, prompt you for the project to know where to auth and put the workspace.

https://github.com/coder/coder/tree/main/examples/templates
https://coder.com/docs/coder-oss/latest/templates

# Error pinging Docker server: Got permission denied
Coder runs as the `coder` user so you have to add `coder` to `docker` group.
```console
sudo usermod -aG docker coder
```
Then verify `coder` is in the group with
```console
grep /etc/group -e "docker"
```

## Resources
