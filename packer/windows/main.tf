provider "aws" {
  version = "~> 2.0"
  region = "us-east-1"
}

locals {
  windows_ami = "ami-045f8603a6a480044"
}

resource "aws_instance" "windows" {
  ami = local.windows_ami
  instance_type = "t2.medium"
  key_name = "buildbot-key"
  subnet_id = "subnet-0fc32b6dc9692fd13"
  iam_instance_profile = "ec2_buildbot_worker_instance_profile"
  vpc_security_group_ids = ["sg-048857df200b4ef4f", "sg-0f59e118151d0f235"]
}

output "windows_instance_public_ic" {
  value = aws_instance.windows.public_ip
}
