provider "aws" {
  region = "eu-west-3"
}

module "ec2_bastion" {
  source        = "git::https://github.com/yurll/terraform-aws-bastion-openvpn.git"
  image_type    = "t3.micro"
  vpc           = "vpc-12345678"
  public_subnet = "subnet-12345678"
  scale_schedule = {
    enabled            = "true"
    morning_recurrence = "0 9 * * 1-5"
    night_recurrence   = "0 18 * * 1-5"
  }
}

output "private_key_pem" {
  description = "Private key data in PEM (RFC 1421) format"
  value       = module.ec2_bastion.private_key_pem
  sensitive   = true
}
