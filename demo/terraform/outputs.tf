# outputs.tf

output "vault_address" {
  description = "The address of the Vault server."
  value       = var.vault_address
}

output "vault_root_token" {
  description = "The root token for Vault."
  value       = var.vault_root_token
  sensitive   = true
}

output "k3d_cluster_name" {
  description = "Name of the k3d cluster."
  value       = module.k3d_cluster.name
}
