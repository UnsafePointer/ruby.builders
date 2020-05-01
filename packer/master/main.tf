provider "aws" {
  version = "~> 2.0"
  region = "us-east-1"
}

resource "aws_instance" "linux" {
  ami = "ami-0fd1d3e92f035fa7d"
  instance_type = "t3.nano"
  key_name = "buildbot-key"
  subnet_id = "subnet-00b50522e25b556a8"
  iam_instance_profile = "ec2_buildbot_master_instance_profile"
  vpc_security_group_ids = ["sg-0fc49665b3a2035ae"]
}

output "instance_public_ic" {
  value = aws_instance.linux.public_ip
}
