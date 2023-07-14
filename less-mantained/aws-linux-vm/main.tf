terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.5.2"
    }
  }
}

# Last updated 2022-05-31
# aws ec2 describe-regions | jq -r '[.Regions[].RegionName] | sort'
variable "region" {
  description = "What region should your workspace live in?"
  default     = "us-east-1"
  validation {
    condition = contains([
      "ap-northeast-1",
      "ap-northeast-2",
      "ap-northeast-3",
      "ap-south-1",
      "ap-southeast-1",
      "ap-southeast-2",
      "ca-central-1",
      "eu-central-1",
      "eu-north-1",
      "eu-west-1",
      "eu-west-2",
      "eu-west-3",
      "sa-east-1",
      "us-east-1",
      "us-east-2",
      "us-west-1",
      "us-west-2"
    ], var.region)
    error_message = "Invalid region!"
  }
}

variable "instance_type" {
  description = "What instance type should your workspace use?"
  default     = "t3.micro"
  validation {
    condition = contains([
      "t3.micro",
      "t3.small",
      "t3.medium",
      "t3.large",
      "t3.xlarge",
      "t3.2xlarge",
    ], var.instance_type)
    error_message = "Invalid instance type!"
  }
}

provider "aws" {
  region = var.region
}

data "coder_workspace" "me" {
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)

  see https://dotfiles.github.io
  EOF
  default = ""
}

resource "coder_agent" "main" {
  arch = "amd64"
  auth = "aws-instance-identity"
  os   = "linux"

  startup_script = <<EOT
  #!/bin/bash

  # install code-server
  curl -fsSL https://code-server.dev/install.sh | sh
  code-server --auth none --port 13337 &

  # use coder CLI to clone and install dotfiles
  coder dotfiles -y ${var.dotfiles_uri}

    EOT 

}

resource "coder_app" "code-server" {
  agent_id = coder_agent.main.id
  name     = "VS Code"
  url      = "http://localhost:13337/?folder=/home/${lower(data.coder_workspace.me.owner)}"
  icon     = "/icon/code.svg"
}

locals {

  # User data is used to stop/start AWS instances. See:
  # https://github.com/hashicorp/terraform-provider-aws/issues/22

  user_data_start = <<EOT
Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
hostname: ${lower(data.coder_workspace.me.name)}
users:
- name: ${lower(data.coder_workspace.me.owner)}
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
sudo --preserve-env=CODER_AGENT_TOKEN -u ${lower(data.coder_workspace.me.owner)} /bin/bash -c '${coder_agent.main.init_script}'
--//--
EOT

  user_data_end = <<EOT
Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
sudo shutdown -h now
--//--
EOT

  # Ensure Coder username is a valid Linux username
  linux_user = lower(substr(data.coder_workspace.me.owner, 0, 32))

}

resource "aws_instance" "dev" {
  ami               = data.aws_ami.ubuntu.id
  availability_zone = "${var.region}a"
  instance_type     = var.instance_type

  user_data = data.coder_workspace.me.transition == "start" ? local.user_data_start : local.user_data_end
  tags = {
    Name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    # Required if you are using our example policy, see template README
    Coder_Provisioned = "true"
  }
}

resource "coder_metadata" "workspace_info" {
  resource_id = aws_instance.dev.id
  item {
    key   = "region"
    value = var.region
  }
  item {
    key   = "instance type"
    value = aws_instance.dev.instance_type
  }
  item {
    key   = "vm image"
    value = data.aws_ami.ubuntu.name
  }  
  item {
    key   = "disk"
    value = "${aws_instance.dev.root_block_device[0].volume_size} GiB"
  }
}