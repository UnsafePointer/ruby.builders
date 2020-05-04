provider "aws" {
  version = "~> 2.0"
  region = "us-east-1"
}

data "aws_ami" "buildbot_master_ami" {
  most_recent = true
  name_regex = "^buildbot-master"
  owners = ["self"]

  filter {
    name   = "name"
    values = ["buildbot-master"]
  }

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

data "aws_ssm_parameter" "buildbot_master_instance_profile" {
  name = "/buildbot/master_instance_profile"
}

data "aws_ssm_parameter" "buildbot_allow_ssh_sg" {
  name = "/buildbot/allow_ssh_sg"
}

resource "aws_instance" "linux" {
  ami = data.aws_ami.buildbot_master_ami.image_id
  instance_type = "t3.nano"
  key_name = data.aws_ssm_parameter.buildbot_keypair_name.value
  subnet_id = data.aws_ssm_parameter.buildbot_subnet.value
  iam_instance_profile = data.aws_ssm_parameter.buildbot_master_instance_profile.value
  vpc_security_group_ids = [data.aws_ssm_parameter.buildbot_allow_ssh_sg.value]
}

output "instance_public_ic" {
  value = aws_instance.linux.public_ip
}
