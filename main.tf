provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

locals {
  availability_zones = ["us-east-1a", "us-east-1b"]
}

resource "aws_vpc" "buildbot_micro" {
  cidr_block = "172.18.0.0/24"
  tags = {
    Name = "buildbot_micro"
  }
}
