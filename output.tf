output "private_key_pem" {
  description = "Private key data in PEM (RFC 1421) format"
  value       = try(trimspace(tls_private_key.generated_key[0].private_key_pem), "")
  sensitive   = true
}
