output "private_key_pem" {
  description = "Private key data in PEM (RFC 1421) format"
  value       = try(trimspace(tls_private_key.generated_key[0].private_key_pem), "")
  sensitive   = true
}

output "openvpn_security_group_id" {
  description = "ID of the security group created for OpenVPN bastion host"
  value       = aws_security_group.managed_sg.id
}
