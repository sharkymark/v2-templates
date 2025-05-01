---
name: Develop in Linux on AWS EC2 (Ephemeral, Persistent Home)
description: Get started with Linux development on AWS EC2 where only the home volume is persisted.
tags: [cloud, aws]
icon: /icon/aws.png
---

# aws-linux-ephemeral

This template gives developers ephemeral AWS instances. When a workspace is restarted, all data is lost except files in `/home/coder/` which is persisted by a seperate EBS volume.

## Authentication

This template prompts the template administrator for the AWS credentials which are stored in the Coder database

## Web IDE

`code-server`, Coder's VS Code in a browser OSS project, is installed via the `startup_script` argument in the `coder_agent`
resource block. The `coder_app` resource is defined to access `code-server` through
the dashboard UI over `localhost:13337`.

## Dotfiles

At workspace creation, the user can enter their dotfiles repository which Coder clones and runs in the `startup_script`

## Resources

[EBS Volumes and NVMe on Linux instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nvme-ebs-volumes.html)



