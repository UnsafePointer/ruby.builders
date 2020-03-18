provider "aws" {
  version = "~> 2.0"
  region = "us-east-1"
}

resource "aws_security_group" "allow_ssh_sh" {
  name = "allow_ssh_sh"
  vpc_id = "vpc-063d97317ad396653"
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh_sh"
  }
}

resource "aws_instance" "linux" {
  ami = "ami-071ed599e620d2300"
  instance_type = "t2.micro"
  key_name = "buildbot-key"
  subnet_id = "subnet-0fc32b6dc9692fd13 "
  iam_instance_profile = "ec2_buildbot_worker_instance_profile"
  vpc_security_group_ids = [aws_security_group.allow_ssh_sh.id]
}

output "instance_public_ic" {
  value = aws_instance.linux.public_ip
}
