terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
  }
}

provider "coder" {
  feature_use_managed_variables = "true"
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

# To retrieve latest regions from AWS CLI
# aws ec2 describe-regions | jq -r '[.Regions[].RegionName] | sort'
data "coder_parameter" "region" {
  name        = "Region"
  description = "The region to deploy the workspace in."
  default     = "us-west-1"
  mutable     = false

  option {
    name  = "US West (N. California)"
    value = "us-west-1"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US East (N. Virginia)"
    value = "us-east-1"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }  
  option {
    name  = "US West (Oregon)"
    value = "us-west-2"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "South America (São Paulo)"
    value = "sa-east-1"
    icon  = "/emojis/1f1e7-1f1f7.png"
  }
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
}

data "coder_parameter" "instance_type" {
  name        = "EC2 Instance Type"
  description = "What instance type should your workspace use?"
  default     = "t3.micro"
  mutable     = false
  option {
    name  = "2 vCPU, 1 GiB RAM t3.micro"
    value = "t3.micro"
  }
  option {
    name  = "2 vCPU, 2 GiB RAM t3.small"
    value = "t3.small"
  } 
  option {
    name  = "2 vCPU, 4 GiB RAM t3.medium"
    value = "t3.medium"
  }
  option {
    name  = "2 vCPU, 8 GiB RAM t3.large"
    value = "t3.large"
  }
  option {
    name  = "4 vCPU, 16 GiB RAM t3.xlarge"
    value = "t3.xlarge"
  }
  option {
    name  = "8 vCPU, 32 GiB RAM t3.2xlarge"
    value = "t3.2xlarge"
  }
}

data "coder_parameter" "disk_size" {
  name        = "Home volume persistent storage size"
  type        = "number"
  description = "Number of GB of storage"
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 15
    max       = 50
  }
  mutable     = false
  default     = 15
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL"
  description = "Personalize your workspace"
  type        = "string"
  default     = "git@github.com:sharkymark/dotfiles.git"
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
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

resource "coder_agent" "main" {
  arch           = "amd64"
  auth           = "aws-instance-identity"


  metadata {
    display_name = "Memory Usage"
    key  = "pod-mem"
    script = "awk '{ print $1 }' /sys/fs/cgroup/memory/memory.usage_in_bytes | numfmt --to=iec"
    interval = 1
    timeout = 1
  }

  metadata {
    display_name = "CPU Usage"
    key  = "cpu"
    # calculates CPU usage by summing the "us", "sy" and "id" columns of
    # vmstat.
    script = <<EOT
        top -bn1 | awk 'FNR==3 {printf "%2.0f%%", $2+$3+$4}'
        #vmstat | awk 'FNR==3 {printf "%2.0f%%", $13+$14+$16}'
    EOT
    interval = 10
    timeout = 1
  }

  metadata {
    display_name = "Disk Usage"
    key  = "disk"
    script = "df /home/coder | awk NR==2'{print $5}'"
    interval = 600
    timeout = 1
  }

  metadata {
    display_name = "Memory Used"
    key  = "mem3"
    script = <<EOT
    free | awk '/^Mem/ { printf("%.0f%%", $3/$2 * 100.0) }'
    EOT
    interval = 10
    timeout = 1
  }   

  os             = "linux"
  startup_script = <<EOT
    #!/bin/bash

    # install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

    # use coder CLI to clone and install dotfiles
    if [[ ! -z "${data.coder_parameter.dotfiles_url.value}" ]]; then
      coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
    fi

  EOT
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code Web"
  url          = "http://localhost:13337/?folder=/home/coder"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}

locals {

  linux_user = "coder" # Ensure this user/group does not exist in your AMI
  user_data  = <<EOT
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
hostname: ${lower(data.coder_workspace.me.name)}
users:
- name: ${local.linux_user}
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: /bin/bash

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash

sudo apt update -y

# Format the drive if there is no filesystem
if [[ $(sudo file -s /dev/nvme1n1) == "/dev/nvme1n1: data" ]]; then
  sudo mkfs -t ext4 /dev/nvme1n1
  sudo cp -rT /home/coder /tmp/${local.linux_user}
  echo "Initialized filesystem on /dev/nvme1n1"
fi

mount /dev/nvme1n1 /home/${local.linux_user}
echo "Mounted home volume"

# Copy the sample home directory, if empty
if [ -d "/home/${local.linux_user}" ]; then
  sudo cp -rT /tmp/${local.linux_user} /home/coder
  echo "Home directory seeded with operating system files"
  chown -R 1000:1000 /home/${local.linux_user}
fi

sudo -u ${local.linux_user} sh -c '${coder_agent.main.init_script}'
--//--
EOT


}

# Ephemeral AWS Instance (deleted on stop)
resource "aws_instance" "dev" {
  count             = data.coder_workspace.me.start_count
  ami               = data.aws_ami.ubuntu.id
  availability_zone = "${data.coder_parameter.region.value}a"
  instance_type     = data.coder_parameter.instance_type.value

  user_data = local.user_data
  tags = {
    Name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    # Required if you are using our example policy, see template README
    Coder_Provisioned = "true"
  }
}

# Persistent EBS "home" volume (for /home/coder)
resource "aws_ebs_volume" "home" {
  availability_zone = "${data.coder_parameter.region.value}a"
  size              = data.coder_parameter.disk_size.value

  tags = {
    Name = "coder-homedir-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    # Required if you are using our example policy, see template README
    Coder_Provisioned = "true"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  count       = data.coder_workspace.me.start_count
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.home.id
  instance_id = aws_instance.dev[0].id
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = aws_instance.dev[0].id
  item {
    key   = "region"
    value = data.coder_parameter.region.value
  }
  item {
    key   = "instance type"
    value = aws_instance.dev[0].instance_type
  }
  item {
    key   = "availability zone"
    value = aws_ebs_volume.home.availability_zone
  }  
  item {
    key   = "home volume size"
    value = "${data.coder_parameter.disk_size.value}GB"
  }    
}
