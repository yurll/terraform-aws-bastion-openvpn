# Terraform Module: Bastion with OpenVPN and Self-Healing Logic

## Overview
This Terraform module deploys a self-healing Bastion server configured with OpenVPN to allow secure access to nearby servers. It includes features like scheduled auto-scaling, managed security groups, user-data for instance initialization, and automated Elastic IP (EIP) assignment. Additionally, this module includes options for persistent `iptables` configuration and OpenVPN setup with S3 backup support.

## Features
- **Elastic Compute Cloud (EC2) Instance** in an **Auto Scaling Group** with user-data for configuration.
- Automatic **EIP** attachment for persistent IP address when using OpenVPN.
- Managed **Security Group** with configurable inbound rules.
- Persistent `iptables` configuration for OpenVPN traffic routing.
- OpenVPN installation, configuration, and backup logic.
- Integration with **S3** for OpenVPN configuration backup and restore.
- Support for scheduled scaling policies.

## Inputs
| Variable           | Description                                                                                       | Type           | Default                     |
|--------------------|---------------------------------------------------------------------------------------------------|----------------|-----------------------------|
| `prefix_name`      | Prefix for resource naming. If not set, a random string will be appended.                        | `string`       | `null`                      |
| `image_type`       | Instance type for the EC2 instances.                                                             | `string`       | `t2.micro`                  |
| `key_pair`         | Name of the key pair for SSH access. If not provided, a new one will be created.                 | `string`       | `null`                      |
| `vpc_id`           | VPC ID where the resources will be deployed.                                                     | `string`       | n/a                         |
| `subnet_id`        | Subnet ID where the instances will be deployed.                                                  | `string`       | n/a                         |
| `allowed_cidrs`    | List of CIDRs allowed for inbound traffic.                                                       | `list(string)` | `["0.0.0.0/0"]`             |
| `open_ports`       | Map of ports to their protocols (e.g., `{22 = "tcp", 1194 = "tcp"}`).                         | `map(string)`  | `{22 = "tcp", 1194 = "udp"}` |            |
| `s3_bucket_name`   | S3 bucket name for OpenVPN configuration backups.                                                | `string`       | `null`                      |
| `scale_schedule`   | Scaling schedule for Auto Scaling Group in `morning_recurrence` and `night_recurrence` configurations.                 | `map(string)`  | {<br>&emsp;"enabled"            = "true "<br> &emsp;"morning_recurrence" = "0 9 * * 1-5" <br> &emsp;"night_recurrence"   = "0 18 * * 1-5" <br> }|
| `morning_recurrence` | CRON expression for scaling up in the morning (UTC Time) | 0 9 * * 1-5 |
| `night_recurrence` | CRON expression for scaling down at night | 0 18 * * 1-5

## Outputs
| Output                | Description                                |
|-----------------------|--------------------------------------------|
| `private_key_pem`   | Generated private key data in PEM (RFC 1421) format |

## Usage
```hcl
module "bastion" {
  source       = "./path-to-module"
  prefix_name  = "bastion-server"
  use_prefix   = true
  image_type   = "t3.micro"
  key_pair     = "my-key-pair"
  vpc_id       = "vpc-12345678"
  subnet_id    = "subnet-12345678"
  scale_schedule = {
    enabled            = "true"
    morning_recurrence = "0 9 * * 1-5"
    night_recurrence   = "0 18 * * 1-5"
  }
  allowed_cidrs = ["192.168.1.0/24"]
  open_ports    = {
    22   = "tcp"
    1194 = "udp"
  }
  vpn_subnet = "10.8.0.0/24"
  s3_bucket_name = "my-openvpn-backups"
}
```

## Key Features and Behavior
### Security Groups
- Configurable to allow specific ports and protocols based on user input.
- Default behavior allows SSH (TCP 22) and OpenVPN (TCP/UDP 1194).

### Auto Scaling and Scheduled Actions
- Dynamically scales the Bastion server during specified times (e.g., day and night).
- Scaling schedule is fully customizable.

### OpenVPN Configuration
- Automatically installs and configures OpenVPN.
- Checks if OpenVPN is already configured, downloads a backup if available, or performs an initial setup.
- Backup and restore logic integrated with S3.

### Persistent `iptables` Rules
- NAT rules are applied during instance initialization.
- Rules persist across reboots using iptables service.

## Requirements
- Terraform v1.0+
- AWS CLI and appropriate IAM permissions for managing EC2, S3, and Auto Scaling resources.

## Notes
- Ensure the provided `s3_bucket_name` exists or has permissions to create one if needed.
- Ensure the `key_pair` exists in the region where the resources are being deployed if not auto-created.

## Authors
Developed by Yurii Bohdan.

## License
MIT License. See `LICENSE` for details.

