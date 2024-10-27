# variables.tf

variable "vault_address" {
  type        = string
  description = "The address of the Vault server."
  default     = "http://127.0.0.1:8200"
}

variable "cluster_port" {
  type        = string
  description = "The port of the k3d cluster"
  default     = "6445"
}

variable "vault_root_token" {
  type        = string
  description = "The root token for Vault."
  default     = "myroot"
  sensitive   = true
}

variable "kube_config_path" {
  type        = string
  description = "Path to the Kubernetes config file."
  default     = "~/.kube/config"
}

variable "cluster_name" {
  type        = string
  description = "Kubernetes config context to use."
  default     = "gateway-demo"
}

variable "github_token" {
  type        = string
  description = "GitHub token for authentication."
  sensitive   = true

  validation {
    condition     = length(var.github_token) > 0
    error_message = "The github_token must not be empty."
  }
}

variable "git_repo_url" {
  type        = string
  description = "Git repository URL for Flux."
}

variable "git_branch" {
  type        = string
  description = "Git branch to use."
  default     = "main"
}

variable "git_username" {
  type        = string
  description = "Git username for authentication."
}
