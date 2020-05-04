provider "aws" {
  version = "~> 2.0"
  region = "us-east-1"
}

data "aws_ami" "buildbot_worker_ami" {
  most_recent = true
  name_regex = "^buildbot-worker-windows"
  owners = ["self"]

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ssm_parameter" "buildbot_keypair_name" {
  name = "/buildbot/keypair_name"
}

data "aws_ssm_parameter" "buildbot_subnet" {
  name = "/buildbot/subnet"
}

data "aws_ssm_parameter" "buildbot_worker_instance_profile" {
  name = "/buildbot/workers_instance_profile"
}

data "aws_ssm_parameter" "buildbot_allow_ssh_sg" {
  name = "/buildbot/allow_ssh_sg"
}

data "aws_ssm_parameter" "buildbot_allow_rdp_sg" {
  name = "/buildbot/allow_rdp_sg"
}

data "aws_ssm_parameter" "buildbot_worker_instance_type" {
  name = "/buildbot/worker_instance_type"
}

resource "aws_instance" "windows" {
  ami = data.aws_ami.buildbot_worker_ami.image_id
  instance_type = data.aws_ssm_parameter.buildbot_worker_instance_type.value
  key_name = data.aws_ssm_parameter.buildbot_keypair_name.value
  subnet_id = data.aws_ssm_parameter.buildbot_subnet.value
  iam_instance_profile = data.aws_ssm_parameter.buildbot_worker_instance_profile.value
  vpc_security_group_ids = [data.aws_ssm_parameter.buildbot_allow_ssh_sg.value, data.aws_ssm_parameter.buildbot_allow_rdp_sg.value]
}

output "windows_instance_public_ic" {
  value = aws_instance.windows.public_ip
}
