terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "ganbarubies"

    workspaces {
      name = "production"
    }
  }
}

variable "aws_access_key" {}

variable "aws_secret_key" {}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
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

# Public subnet internet routing

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.buildbot_micro.id
  tags = {
    Name = "${local.vpc_name}_igw"
  }
}

resource "aws_route" "internet_access" {
  route_table_id = aws_vpc.buildbot_micro.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_eip" "eip_gw" {
  count = length(local.availability_zones)
  vpc = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "${local.vpc_name}_eip_gw_${local.availability_zones[count.index]}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count = length(local.availability_zones)
  subnet_id = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.eip_gw.*.id, count.index)
  tags = {
    Name = "${local.vpc_name}_nat_gw_${local.availability_zones[count.index]}"
  }
}

# Private subnet internet routing

resource "aws_route_table" "internet_access" {
  count = length(local.availability_zones)
  vpc_id = aws_vpc.buildbot_micro.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gw.*.id, count.index)
  }
  tags = {
    Name = "${local.vpc_name}_route_table_internet_access_${local.availability_zones[count.index]}"
  }
}

resource "aws_route_table_association" "internet_access_association" {
  count = length(local.availability_zones)
  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.internet_access.*.id, count.index)
}
