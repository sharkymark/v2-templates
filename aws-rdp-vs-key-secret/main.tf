terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "coder" {

}

variable "access-key-id" {
  sensitive   = true
  description = <<-EOF
  Enter an AWS Access key id

  EOF
  default = ""
}

variable "secret-access-key" {
  sensitive   = true
  description = <<-EOF
  Enter an AWS Secret Access key

  EOF
  default = ""
}

provider "aws" {
  region      = data.coder_parameter.region.value
  access_key  = var.access-key-id
  secret_key  = var.secret-access-key 
}

# Last updated 2023-03-14
# aws ec2 describe-regions | jq -r '[.Regions[].RegionName] | sort'
data "coder_parameter" "region" {
  name         = "region"
  display_name = "Region"
  description  = "The region to deploy the workspace in."
  default      = "us-east-1"
  mutable      = false
  option {
    name  = "Asia Pacific (Tokyo)"
    value = "ap-northeast-1"
    icon  = "/emojis/1f1ef-1f1f5.png"
  }
  option {
    name  = "Asia Pacific (Seoul)"
    value = "ap-northeast-2"
    icon  = "/emojis/1f1f0-1f1f7.png"
  }
  option {
    name  = "Asia Pacific (Osaka-Local)"
    value = "ap-northeast-3"
    icon  = "/emojis/1f1f0-1f1f7.png"
  }
  option {
    name  = "Asia Pacific (Mumbai)"
    value = "ap-south-1"
    icon  = "/emojis/1f1f0-1f1f7.png"
  }
  option {
    name  = "Asia Pacific (Singapore)"
    value = "ap-southeast-1"
    icon  = "/emojis/1f1f0-1f1f7.png"
  }
  option {
    name  = "Asia Pacific (Sydney)"
    value = "ap-southeast-2"
    icon  = "/emojis/1f1f0-1f1f7.png"
  }
  option {
    name  = "Canada (Central)"
    value = "ca-central-1"
    icon  = "/emojis/1f1e8-1f1e6.png"
  }
  option {
    name  = "EU (Frankfurt)"
    value = "eu-central-1"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "EU (Stockholm)"
    value = "eu-north-1"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "EU (Ireland)"
    value = "eu-west-1"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "EU (London)"
    value = "eu-west-2"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "EU (Paris)"
    value = "eu-west-3"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "South America (São Paulo)"
    value = "sa-east-1"
    icon  = "/emojis/1f1e7-1f1f7.png"
  }
  option {
    name  = "US East (N. Virginia)"
    value = "us-east-1"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US East (Ohio)"
    value = "us-east-2"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US West (N. California)"
    value = "us-west-1"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US West (Oregon)"
    value = "us-west-2"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
}

data "coder_parameter" "instance_type" {
  name         = "instance_type"
  display_name = "Instance type"
  description  = "What instance type should your workspace use?"
  default      = "t3.large"
  mutable      = false
  option {
    name  = "2 vCPU, 1 GiB RAM"
    value = "t3.micro"
  }
  option {
    name  = "2 vCPU, 2 GiB RAM"
    value = "t3.small"
  }
  option {
    name  = "2 vCPU, 4 GiB RAM"
    value = "t3.medium"
  }
  option {
    name  = "2 vCPU, 8 GiB RAM"
    value = "t3.large"
  }
  option {
    name  = "4 vCPU, 16 GiB RAM"
    value = "t3.xlarge"
  }
  option {
    name  = "8 vCPU, 32 GiB RAM"
    value = "t3.2xlarge"
  }
}

data "coder_workspace" "me" {
}

data "coder_parameter" "os" {
  name                = "os"
  display_name        = "Windows OS"
  type                = "string"
  description         = "What release of Microsoft Windows Server?"
  mutable             = false
  default             = "Windows_Server-2022-English-Full-Base-*"

  option {
    name = "2022"
    value = "Windows_Server-2022-English-Full-Base-*"
  }
  option {
    name = "2019"
    value = "Windows_Server-2019-English-Full-Base-*"
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["${data.coder_parameter.os.value}"]
  }
}

data "coder_parameter" "vs" {
  name                = "vs"  
  display_name        = "Visual Studio"
  type                = "string"
  description         = "What release of Microsoft Visual Studio Community?"
  mutable             = false
  default             = "visualstudio2022community"

  option {
    name = "2022"
    value = "visualstudio2022community"
  }
  option {
    name = "2019"
    value = "visualstudio2019community"
  }
}




resource "coder_agent" "main" {
  arch           = "amd64"
  auth           = "aws-instance-identity"
  os             = "windows"

 # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "sshd.exe stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "sshd.exe stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "sshd.exe stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  } 

  startup_script_behavior = "non-blocking"
  #startup_script_timeout = 500   

  startup_script = <<EOF
# Set admin password
Get-LocalUser -Name "Administrator" | Set-LocalUser -Password (ConvertTo-SecureString -AsPlainText "${local.admin_password}" -Force)
# To disable password entirely, see https://serverfault.com/a/968240

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0

# Enable RDP through Windows Firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Disable Network Level Authentication (NLA)
# Clients will connect via Coder's tunnel
(Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -ComputerName $env:COMPUTERNAME -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0)

choco feature enable -n=allowGlobalConfirmation

# install microsoft visual studio community edition
choco install ${data.coder_parameter.vs.value} --package-parameters "--add=Microsoft.VisualStudio.Workload.ManagedDesktop;includeRecommended --passive --locale en-US"

EOF
}

locals {
  # Password to log in via RDP
  #
  # Must meet Windows password complexity requirements:
  # https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements#reference
  admin_password = "coderRDP!"

  # User data is used to stop/start AWS instances. See:
  # https://github.com/hashicorp/terraform-provider-aws/issues/22
  user_data_start = <<EOT
<powershell>

# Install Chocolatey package manager before
# the agent starts to use via startup_script
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Reload path so sessions include "choco" and "refreshenv"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install Git and reload path
choco install -y git
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
${coder_agent.main.init_script}
</powershell>
<persist>true</persist>
EOT

  user_data_end = <<EOT
<powershell>
shutdown /s
</powershell>
<persist>true</persist>
EOT
}

resource "aws_instance" "dev" {
  ami               = data.aws_ami.windows.id
  availability_zone = "${data.coder_parameter.region.value}a"
  instance_type     = data.coder_parameter.instance_type.value

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
    key       = "Administrator password"
    value     = local.admin_password
    sensitive = true
  }
  item {
    key   = "region"
    value = data.coder_parameter.region.value
  }
  item {
    key   = "instance type"
    value = aws_instance.dev.instance_type
  }
  item {
    key   = "windows os"
    value = "${data.coder_parameter.os.value}"
  }  
  item {
    key   = "visual studio"
    value = "${data.coder_parameter.vs.value}"
  }     
}