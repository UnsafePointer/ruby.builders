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

variable "buildbot_admin_username" {}

variable "buildbot_admin_password" {}

variable "buildbot_linux_worker_username" {}

variable "buildbot_windows_worker_username" {}

variable "buildbot_worker_password" {}

variable "buildbot_github_hook_secret" {}

variable "buildbot_github_api_token" {}

provider "aws" {
  version = "~> 2.0"
  region  = local.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

locals {
  vpc_name = "buildbot_micro"
  domain = "ruby.builders"
  region = "us-east-1"
  availability_zones = ["us-east-1a"]
  master_instance_type = "t3.nano"
}

resource "aws_vpc" "buildbot_micro" {
  cidr_block = "172.18.0.0/24"
  tags = {
    Name = local.vpc_name
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

resource "aws_eip" "eip" {
  vpc = true
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

# security

resource "aws_security_group" "allow_ssl_sg" {
  name = "allow_ssl_sg"
  vpc_id = aws_vpc.buildbot_micro.id
  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssl_sg"
  }
}

resource "aws_security_group" "buildbot_workers_sg" {
  name = "buildbot_workers_sg"
  vpc_id = aws_vpc.buildbot_micro.id
  ingress {
    protocol = "tcp"
    from_port = 9989
    to_port = 9989
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "buildbot_workers_sg"
  }
}

resource "aws_security_group" "allow_ssh_sh" {
  name = "allow_ssh_sh"
  vpc_id = aws_vpc.buildbot_micro.id
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

resource "aws_security_group" "allow_rdp_sg" {
  name = "allow_rdp_sg"
  vpc_id = aws_vpc.buildbot_micro.id
  ingress {
    protocol = "tcp"
    from_port = 3389
    to_port = 3389
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_rdp_sg"
  }
}

# IAM ECS tasks policy

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ec2_instances_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "aws_iam_policy_buildbot_ec2" {
  name = "aws_iam_policy_buildbot_ec2"
  path = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "ec2:GetConsole*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
              "ec2:RunInstances",
              "ec2:AssociateIamInstanceProfile",
              "ec2:ReplaceIamInstanceProfileAssociation",
              "ec2:AssociateAddress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteTags",
                "ec2:DescribeTags",
                "ec2:CreateTags",
                "ec2:TerminateInstances",
                "ec2:StopInstances"
            ],
            "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": "iam:PassRole",
          "Resource": "*"
        }
    ]
}
EOF
}

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

resource "aws_iam_policy" "aws_iam_policy_buildbot_route53" {
  name        = "aws_iam_policy_buildbot_route53"
  path        = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:GetChange",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "ec2_buildbot_master_role" {
  name = "${local.vpc_name}_ec2_buildbot_master_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_instances_policy_document.json
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_route53_policy_attachment" {
  role = aws_iam_role.ec2_buildbot_master_role.name
  policy_arn = aws_iam_policy.aws_iam_policy_buildbot_route53.arn
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_ssm_policy_attachment" {
  role = aws_iam_role.ec2_buildbot_master_role.name
  policy_arn = aws_iam_policy.aws_iam_policy_buildbot_ssm.arn
}

resource "aws_iam_role_policy_attachment" "ecs_tasks_ec2_policy_attachment" {
  role = aws_iam_role.ec2_buildbot_master_role.name
  policy_arn = aws_iam_policy.aws_iam_policy_buildbot_ec2.arn
}

resource "aws_iam_instance_profile" "ec2_buildbot_master_instance_profile" {
  name = "ec2_buildbot_master_instance_profile"
  role = aws_iam_role.ec2_buildbot_master_role.name
}

resource "aws_iam_role" "ec2_buildbot_worker_role" {
  name = "${local.vpc_name}_ec2_buildbot_worker_role"
  assume_role_policy = data.aws_iam_policy_document.ec2_instances_policy_document.json
}

resource "aws_iam_role_policy_attachment" "buildbot_worker_ssm_policy_attachment" {
  role = aws_iam_role.ec2_buildbot_worker_role.name
  policy_arn = aws_iam_policy.aws_iam_policy_buildbot_ssm.arn
}

resource "aws_iam_role_policy_attachment" "buildbot_worker_ec2_policy_attachment" {
  role = aws_iam_role.ec2_buildbot_worker_role.name
  policy_arn = aws_iam_policy.aws_iam_policy_buildbot_ec2.arn
}

resource "aws_iam_instance_profile" "ec2_buildbot_worker_instance_profile" {
  name = "ec2_buildbot_worker_instance_profile"
  role = aws_iam_role.ec2_buildbot_worker_role.name
}

# EC2

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

resource "aws_launch_configuration" "buildbot_launch_cfg" {
  name_prefix = "buildbot_launch_cfg"
  image_id = data.aws_ami.buildbot_master_ami.image_id
  instance_type = local.master_instance_type
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_buildbot_master_instance_profile.name
  key_name = aws_key_pair.buildbot.key_name
  security_groups = [aws_security_group.allow_ssh_sh.id, aws_security_group.allow_ssl_sg.id, aws_security_group.buildbot_workers_sg.id]
  root_block_device {
    delete_on_termination = true
    volume_size = 10
    volume_type = "gp2"
  }
  user_data = <<EOF
#cloud-config
runcmd:
  - aws ec2 associate-address --instance-id $(curl http://169.254.169.254/latest/meta-data/instance-id) --allocation-id ${aws_eip.eip.id} --allow-reassociation
  - certbot renew
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "buildbot_asg" {
  name = "buildbot_asg"
  health_check_type = "EC2"
  launch_configuration = aws_launch_configuration.buildbot_launch_cfg.name
  max_size = 1
  min_size = 1
  vpc_zone_identifier = aws_subnet.public.*.id
}

# SSM parameters

resource "aws_ssm_parameter" "buildbot_web_url" {
  name  = "/buildbot/web-url"
  type  = "String"
  value = "https://${local.domain}/"
}

resource "aws_ssm_parameter" "buildbot_admin_username" {
  name  = "/buildbot/admin-username"
  type  = "SecureString"
  value = var.buildbot_admin_username
}

resource "aws_ssm_parameter" "buildbot_admin_password" {
  name  = "/buildbot/admin-password"
  type  = "SecureString"
  value = var.buildbot_admin_password
}

resource "aws_ssm_parameter" "buildbot_linux_worker_username" {
  name  = "/buildbot/worker/linux-worker-username"
  type  = "SecureString"
  value = var.buildbot_linux_worker_username
}

resource "aws_ssm_parameter" "buildbot_windows_worker_username" {
  name  = "/buildbot/worker/windows-worker-username"
  type  = "SecureString"
  value = var.buildbot_windows_worker_username
}

resource "aws_ssm_parameter" "buildbot_worker_password" {
  name  = "/buildbot/worker/worker-password"
  type  = "SecureString"
  value = var.buildbot_worker_password
}

resource "aws_ssm_parameter" "buildbot_github_hook_secret" {
  name  = "/buildbot/github_hook_secret"
  type  = "SecureString"
  value = var.buildbot_github_hook_secret
}

resource "aws_ssm_parameter" "buildbot_github_api_token" {
  name  = "/buildbot/github_api_token"
  type  = "SecureString"
  value = var.buildbot_github_api_token
}

resource "aws_ssm_parameter" "buildbot_allow_ssh_sg" {
  name  = "/buildbot/allow_ssh_sg"
  type  = "String"
  value = aws_security_group.allow_ssh_sh.id
}

resource "aws_ssm_parameter" "buildbot_allow_rdp_sg" {
  name  = "/buildbot/allow_rdp_sg"
  type  = "String"
  value = aws_security_group.allow_rdp_sg.id
}

resource "aws_ssm_parameter" "buildbot_subnet" {
  name  = "/buildbot/subnet"
  type  = "String"
  value = element(aws_subnet.public.*.id, 0)
}

resource "aws_ssm_parameter" "buildbot_workers_instance_profile" {
  name  = "/buildbot/workers_instance_profile"
  type  = "String"
  value = aws_iam_instance_profile.ec2_buildbot_worker_instance_profile.name
}

resource "aws_ssm_parameter" "buildbot_master_instance_profile" {
  name  = "/buildbot/master_instance_profile"
  type  = "String"
  value = aws_iam_instance_profile.ec2_buildbot_master_instance_profile.name
}

resource "aws_ssm_parameter" "buildbot_keypair_name" {
  name  = "/buildbot/keypair_name"
  type  = "String"
  value = aws_key_pair.buildbot.key_name
}

# Route 53

resource "aws_route53_zone" "public_hosted_zone" {
  name = local.domain
}

resource "aws_route53_zone" "workers_subdomain_public_hosted_zone" {
  name = "workers.${local.domain}"
}

resource "aws_route53_record" "domain_record" {
  zone_id = aws_route53_zone.public_hosted_zone.zone_id
  name = local.domain
  type = "A"
  ttl = "300"
  records = [aws_eip.eip.public_ip]
}

resource "aws_route53_record" "workers_subdomain_ns_record" {
  zone_id = aws_route53_zone.public_hosted_zone.zone_id
  name    = "workers.${local.domain}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.workers_subdomain_public_hosted_zone.name_servers.0}",
    "${aws_route53_zone.workers_subdomain_public_hosted_zone.name_servers.1}",
    "${aws_route53_zone.workers_subdomain_public_hosted_zone.name_servers.2}",
    "${aws_route53_zone.workers_subdomain_public_hosted_zone.name_servers.3}",
  ]
}

resource "aws_route53_record" "workers_subdomain_a_record" {
  zone_id = aws_route53_zone.workers_subdomain_public_hosted_zone.zone_id
  name = "workers.${local.domain}"
  type = "A"
  ttl = "300"
  records = [aws_eip.eip.public_ip]
}

# EC2

resource "aws_key_pair" "buildbot" {
  key_name = "buildbot-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDm7jEeqyLfT+Sy2ksGg8zh7UkZ7mzS72S72LiQF4tdr2zD+03URSW3BZiMQRXN78l25Ddu6rNnKdoJ8JS8ZHMzM4ZlMQMOqo3KJKjya64ChpkmkePMYFf07FL6WPZw+K89+67PB+PbAHzUgEjBC8PRPgGs/ExL/580xqE1xNuJhQlLuI5dgbIrORrOJH8+OjQsOkl8NObnqEI4NvfOqsVZYMWG1GBZ5HJu+UBTuM+k4wcif22bnR0hzf2jdSb4S4NZ9ffoE9Ccwwkye9kuRVvtYZtibRAoh82EuI5umiIbSllxX/FTOVKq9ViYcSd57PxnkgFZSP/3m6Ut6CAPCKEfv7PJC1u/XStm6nVAmNjOJKVLIOG36NTYV7SO3piPy1n7Hw6rfcaJcjA3RTtwD9bVZ4QnStUTTBQO+gky4ED0P+in41eOyz/eNLPGxa0L4aXMArsAcAc0ypaPOsnGO08SVfMcxRiYF7IOZoh3ssz2NDH+/fzEg6XIXWPuHxGG79h5cdYHyal9vnDxVE33gKuJtokayTKtfjQMitwPffr4cl7M2e0W/Qwz7EhiiObMrbedk44z7tpk2wcv33gIrDoF3EAg3bMzWGueAyLsRmcv5UnVVwIhWsYmRJAX4Cp70Toc6L2u/McZTrIYkHNaalOxG5MBVTCQFmqgqHtt1qhwyQ== buildbot@ruby.builders"
}
