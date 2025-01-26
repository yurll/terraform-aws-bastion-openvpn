variable "image_type" {
  description = "Instance type for EC2"
  type        = string
  default     = "t2.micro"
}

variable "key_pair" {
  description = "Key pair name for EC2"
  type        = string
  default     = null
}

variable "vpc" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "public_subnet" {
  description = "Public subnet ID for the instance"
  type        = string
}

variable "scale_schedule" {
  description = "Enable scaling schedule"
  type        = map(string)
  default = {
    "enabled"            = "true"
    "morning_recurrence" = "0 9 * * 1-5"
    "night_recurrence"   = "0 18 * * 1-5"
  }

}

variable "open_ports" {
  description = <<EOT
A map where keys are protocols (e.g., "tcp", "udp") and values are lists of ports to open.
Example:
{
  "tcp" = [22, 443]
  "udp" = [1194]
}
EOT
  type        = map(list(number))
  default = {
    tcp = [22]
    udp = [1194]
  }
}

variable "allowed_cidr" {
  description = "CIDR block for inbound traffic. Defaults to 0.0.0.0/0."
  type        = string
  default     = "0.0.0.0/0"
}


variable "prefix_name" {
  description = "Prefix for naming resources. If null, a randomized prefix will be used."
  type        = string
  default     = null
}
