provider "aws" {
  version = "~> 2.0"
  region = "us-east-1"
}

resource "aws_instance" "linux" {
  ami = "ami-071ed599e620d2300"
  instance_type = "t2.micro"
  key_name = "buildbot-key"
  subnet_id = "subnet-0fc32b6dc9692fd13 "
  iam_instance_profile = "ec2_buildbot_worker_instance_profile"
  vpc_security_group_ids = ["sg-048857df200b4ef4f"]
}

output "instance_public_ic" {
  value = aws_instance.linux.public_ip
}
