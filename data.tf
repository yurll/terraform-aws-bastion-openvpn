data "aws_region" "current" {}

data "aws_vpc" "main" {
  id = var.vpc
}

data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

locals {
  effective_prefix = var.prefix_name != null ? var.prefix_name : "bastion-${random_string.prefix[0].result}"
}
