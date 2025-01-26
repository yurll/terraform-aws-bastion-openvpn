resource "aws_key_pair" "generated" {
  count      = var.key_pair == null ? 1 : 0
  key_name   = "${local.effective_prefix}-key"
  public_key = trimspace(tls_private_key.generated_key[0].public_key_openssh)
}

resource "tls_private_key" "generated_key" {
  count     = var.key_pair == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_string" "prefix" {
  count   = var.prefix_name == null ? 1 : 0
  length  = 8
  upper   = false
  special = false
}

resource "aws_security_group" "managed_sg" {
  name        = "${local.effective_prefix}-sg"
  description = "Managed Security Group for EC2 instances"
  vpc_id      = var.vpc

  dynamic "ingress" {
    for_each = { for protocol, ports in var.open_ports : protocol => ports if length(ports) > 0 }
    content {
      from_port   = ingress.value[0]
      to_port     = ingress.value[0]
      protocol    = ingress.key
      cidr_blocks = [var.allowed_cidr]
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.effective_prefix}-sg"
  }
}

resource "aws_s3_bucket" "openvpn_backup" {
  bucket        = "${local.effective_prefix}-openvpn-backup"
  force_destroy = true

  tags = {
    Name = "${local.effective_prefix}-openvpn-backup"
  }
}

resource "aws_s3_bucket_policy" "openvpn_backup" {
  bucket = aws_s3_bucket.openvpn_backup.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowIAMAccess",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.ec2_role.arn
        },
        Action = "s3:*",
        Resource = [
          "${aws_s3_bucket.openvpn_backup.arn}",
          "${aws_s3_bucket.openvpn_backup.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_launch_template" "example" {
  name          = "${local.effective_prefix}-ec2-scaling-lt"
  image_id      = data.aws_ami.ami.id
  instance_type = var.image_type
  key_name      = var.key_pair != null ? var.key_pair : aws_key_pair.generated[0].key_name
  user_data = base64encode(templatefile("${path.module}/user-data.sh.tftpl", {
    eip_id   = aws_eip.example.id,
    eip      = aws_eip.example.public_ip,
    region   = data.aws_region.current.name,
    bucket   = aws_s3_bucket.openvpn_backup.bucket,
    vpc_net  = cidrhost(data.aws_vpc.main.cidr_block, 0),
    vpc_mask = cidrnetmask(data.aws_vpc.main.cidr_block),
  }))

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [aws_security_group.managed_sg.id]
    subnet_id                   = var.public_subnet
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_role.name
  }
}

resource "aws_autoscaling_group" "example" {
  name             = "${local.effective_prefix}-ec2-asg"
  desired_capacity = 1
  max_size         = 2
  min_size         = 1
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  vpc_zone_identifier = [var.public_subnet]

  tag {
    key                 = "Name"
    value               = "${local.effective_prefix}-ec2-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_schedule" "scale_up" {
  scheduled_action_name  = "scale-up-morning"
  autoscaling_group_name = aws_autoscaling_group.example.name
  count                  = var.scale_schedule["enabled"] == "true" ? 1 : 0

  min_size         = 1
  max_size         = 1
  desired_capacity = 1
  recurrence       = var.scale_schedule["morning_recurrence"]
}

resource "aws_autoscaling_schedule" "scale_down" {
  scheduled_action_name  = "scale-down-night"
  autoscaling_group_name = aws_autoscaling_group.example.name
  count                  = var.scale_schedule["enabled"] == "true" ? 1 : 0

  min_size         = 0
  max_size         = 0
  desired_capacity = 0
  recurrence       = var.scale_schedule["night_recurrence"]
}

resource "aws_eip" "example" {
  domain = "vpc"
  tags = {
    Name = "${local.effective_prefix}-eip"
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${local.effective_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_instance_profile" "ec2_role" {
  name = "${local.effective_prefix}-ec2-role-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_policy" "eip_policy" {
  name = "${local.effective_prefix}-eip-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:AssociateAddress",
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceStatus"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eip_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.eip_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${local.effective_prefix}-instance-profile"
  role = aws_iam_role.ec2_role.name
}
