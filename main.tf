provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

locals {
  vpc_name = "buildbot_micro"
  availability_zones = ["us-east-1a", "us-east-1b"]
}

resource "aws_vpc" "buildbot_micro" {
  cidr_block = "172.18.0.0/24"
  tags = {
    Name = local.vpc_name
  }
}

resource "aws_subnet" "private" {
  count = length(local.availability_zones)
  cidr_block = cidrsubnet(aws_vpc.buildbot_micro.cidr_block, 3, count.index)
  availability_zone = local.availability_zones[count.index]
  vpc_id = aws_vpc.buildbot_micro.id
  tags = {
    Name = "${local.vpc_name}_private_${local.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "public" {
  count = length(local.availability_zones)
  cidr_block = cidrsubnet(aws_vpc.buildbot_micro.cidr_block, 3, length(local.availability_zones) + count.index)
  availability_zone = local.availability_zones[count.index]
  vpc_id = aws_vpc.buildbot_micro.id
  map_public_ip_on_launch = true
  tags = {
    Name = "${local.vpc_name}_public_${local.availability_zones[count.index]}"
  }
}
