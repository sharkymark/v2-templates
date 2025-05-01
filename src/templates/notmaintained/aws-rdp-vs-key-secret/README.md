---
name: Develop in Windows and Visual Studio on AWS EC2
description: Get started with Windows and Visual Studio development on AWS EC2.
tags: [cloud, aws, windows]
---

# Visual Studio IDE on a Windows VM in AWS

Last updated 2023-04-27 with Coder parameters and OS and Visual Studio choices

### Authentication

#### AWS Access Key and Secret Access Key to create an EC2 workspace

This template can be executed where the Coder control plane is Kubernetes - in a different cloud provider - to demonstrate how one control plane can manage multiple cloud resources.

#### Dynamic AWS Credentials

This template prompts the DevOps template administrator at template creation (not workspace creation) for valid AWS Access Key and Secret Access Key credentials. For other ways to authenticate [consult the
Terraform docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

```hcl
provider "aws" {
  region      = data.coder_parameter.region.value
  access_key  = var.access-key
  secret_key  = var.secret-key
}
```

For other ways to authenticate [consult the
Terraform docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

### Apps included
1. A web-based terminal
1. Microsoft Visual Studio 2019 Community Edition

### Additional bash scripting
1. Prompt user for AWS region e.g., us-east-1
1. Prompt user for AWS machine instance type e.g., t3.large
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

## Additional Notes
1. `coder_startup_script.log` is located in `C:\Windows\Temp`
1. Installing Visual Studio will take several minutes, so hang tight.

### Resources

[AWS Terraform provider - instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)

[Microsoft Remote Desktop (macOS)](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466)

[Chocolatey package manager for Windows](https://chocolatey.org/)

[Microsoft Visual Studio Releases](https://learn.microsoft.com/en-us/visualstudio/productinfo/vs-roadmap)

[Microsoft Visual Studio Community home page](https://visualstudio.microsoft.com/vs/community/)

[Getting Started with Visual Studio](https://visualstudio.microsoft.com/vs/getting-started/)

[AWS Regions](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html)

[AWS Instance Types](https://aws.amazon.com/ec2/instance-types/)

[sharkymark's v2 templates](https://github.com/sharkymark/v2-templates)

[Microsoft technical overview of the RDP protocol](https://learn.microsoft.com/en-us/troubleshoot/windows-server/remote/understanding-remote-desktop-protocol)

[RDP on Wikipedia](https://en.wikipedia.org/wiki/Remote_Desktop_Protocol)



