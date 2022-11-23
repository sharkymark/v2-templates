---
name: Develop in Windows and Visual Studio on AWS EC2
description: Get started with Windows and Visual Studio development on AWS EC2.
tags: [cloud, aws, windows]
---

# Visual Studio IDE on a Windows VM in AWS



## Authentication

This template assumes that coderd is run in an environment that is authenticated
with AWS. For example, run `aws configure import` to import credentials on the
system and user running coderd.  For other ways to authenticate [consult the
Terraform docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

### Apps included
1. A web-based terminal
1. Microsoft Visual Studio 2019 Community Edition

### Additional bash scripting
1. Prompt user for AWS region e.g., us-east-1
1. Prompt user for AWS machine instance type e.g., t3.medium
1. Enable RDP
1. Configure Chocolatey to run in non-interactive mode
1. Install Microsoft Visual Studio 2019 Community with Chocolatey

### Known limitations and required steps
1. Add the Coder CLI to your local machine, login and start a tunnel for the RDP port in the workspace

```sh
coder login <your Coder deployment access URL>
coder tunnel <workspace-name> --tcp 3301:3389
```

1. [Microsoft's RDP client](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/remote-desktop-clients) must be installed on the local machine to access the workspace. CoRD RDP client did not connect.
1. Create a new configuration in Microsoft's RDP client, adding 127.0.0.1:3301 as the host, `Administrator` as the username and the password `coderRDP!` and connect.

## Future work
1. Test additional RDP thick clients like CoRD
1. Test browser-based RDP clients like [Apache Guacamole](https://guacamole.apache.org/)


### Resources
[Microsoft Remote Desktop (macOS)](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466)

[Chocolatey package manager for Windows](https://chocolatey.org/)

[Microsoft Visual Studio Releases](https://learn.microsoft.com/en-us/visualstudio/productinfo/vs-roadmap)

[Getting Started with Visual Studio](https://visualstudio.microsoft.com/vs/getting-started/)

[AWS Regions](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html)

[AWS Instance Types](https://aws.amazon.com/ec2/instance-types/)

[sharkymark's v2 templates](https://github.com/sharkymark/v2-templates)

[Microsoft technical overview of the RDP protocol](https://learn.microsoft.com/en-us/troubleshoot/windows-server/remote/understanding-remote-desktop-protocol)

[RDP on Wikipedia](https://en.wikipedia.org/wiki/Remote_Desktop_Protocol)



