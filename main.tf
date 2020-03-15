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
  region  = local.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

locals {
  vpc_name = "buildbot_micro"
  region = "us-east-1"
  availability_zones = ["us-east-1a", "us-east-1b"]
  container_name = "buildbot"
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

# security

resource "aws_security_group" "load_balancer_sg" {
  name = "${local.vpc_name}_load_balancer_sg"
  vpc_id = aws_vpc.buildbot_micro.id
  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.vpc_name}_load_balancer_sg"
  }
}

resource "aws_security_group" "ecs_task_sg" {
  name = "${local.vpc_name}_ecs_task_sg"
  vpc_id = aws_vpc.buildbot_micro.id
  ingress {
    protocol = "tcp"
    from_port = 8010
    to_port = 8010
    security_groups = [aws_security_group.load_balancer_sg.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.vpc_name}_ecs_task_sg"
  }
}

# Application Load Balancer

resource "aws_alb" "buildbot_alb" {
  name = "buildbot-alb"
  subnets = aws_subnet.public.*.id
  security_groups = [aws_security_group.load_balancer_sg.id]
  tags = {
    Name = "${local.vpc_name}_load_balancer"
  }
}

resource "aws_alb_target_group" "buildbot_target_group" {
  name = "buildbot-alb-target-group"
  port = 8010
  protocol = "HTTP"
  vpc_id = aws_vpc.buildbot_micro.id
  target_type = "ip"
  health_check {
    healthy_threshold = "3"
    interval = "30"
    protocol = "HTTP"
    matcher = "200"
    timeout = "3"
    path = "/"
    unhealthy_threshold = "2"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "${local.vpc_name}_target_group"
  }
}

resource "aws_alb_listener" "buildbot_listener" {
  load_balancer_arn = aws_alb.buildbot_alb.id
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.buildbot_target_group.id
    type = "forward"
  }
}

# IAM ECS tasks policy

data "aws_iam_policy_document" "ecs_tasks_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "aws_iam_policy_buildbot_ssm" {
  name        = "aws_iam_policy_buildbot_ssm"
  path        = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/buildbot/*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "ecs_tasks_execution_role" {
  name = "${local.vpc_name}_ecs_task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_policy_document.json
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_policy_attachment" {
  role = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_ssm_policy_attachment" {
  role = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = aws_iam_policy.aws_iam_policy_buildbot_ssm.arn
}

# ECS task with Fargate launch type

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${local.vpc_name}_ecs_cluster"
}

data "template_file" "buildbot_container_definition" {
  template = file("./templates/buildbot.json.tpl")
  vars = {
    image = "${aws_ecr_repository.buildbot_repository.repository_url}:latest"
    name = "buildbot"
    container_port = 8010
  }
}

resource "aws_ecs_task_definition" "buildbot_ecs_task_definition" {
  family = "${local.vpc_name}_task"
  execution_role_arn = aws_iam_role.ecs_tasks_execution_role.arn
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  container_definitions = data.template_file.buildbot_container_definition.rendered
}

resource "aws_ecs_service" "buildbot_ecs_service" {
  name = "${local.vpc_name}_ecs_service"
  cluster = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.buildbot_ecs_task_definition.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    security_groups = [aws_security_group.ecs_task_sg.id]
    subnets = aws_subnet.private.*.id
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.buildbot_target_group.id
    container_name = "buildbot"
    container_port = 8010
  }
  depends_on = [aws_alb_listener.buildbot_listener, aws_iam_role_policy_attachment.ecs_tasks_policy_attachment]
}

# ECR repository

resource "aws_ecr_repository" "buildbot_repository" {
  name = "buildbot"
}

# SSM parameters

resource "aws_ssm_parameter" "buildbot_web_url" {
  name  = "/buildbot/web-url"
  type  = "String"
  value = "http://${aws_alb.buildbot_alb.dns_name}/"
}

# CloudWatch

resource "aws_cloudwatch_log_group" "hello_world" {
  name = local.container_name
  retention_in_days = 1
}
