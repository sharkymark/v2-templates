---
name: Develop in Linux on AWS EC2
description: Dynamically config an AWS key and secret access key to provision an AWS EC2.
tags: [cloud, aws]
icon: /icon/aws.png
---

# AWS Access Key and Secret Access Key to create an EC2 workspace

This template can be executed where the Coder control plane is Kubernetes - in a different cloud provider - to demonstrate how one control plane can manage multiple cloud resources.

## Dynamic AWS Credentials

This template prompts the DevOps template administrator at template creation (not workspace creation) for valid AWS Access Key and Secret Access Key credentials. For other ways to authenticate [consult the
Terraform docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

```hcl
provider "aws" {
  region      = data.coder_parameter.region.value
  access_key  = var.access-key
  secret_key  = var.secret-key
}
```

## `bash` scripting

1. `code-server` is installed and started via the `startup_script` argument in the `coder_agent`
   resource block.

### Resources

[AWS Terraform Provider docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)
