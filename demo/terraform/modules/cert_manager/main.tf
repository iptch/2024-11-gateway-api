# modules/cert_manager/main.tf

variable "kubernetes_host" {
  type        = string
  description = "Kubernetes API server endpoint."
}

variable "pki_int_path" {
  type = string
}

variable "role_name" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}


# Wait for Kubernetes to be ready
data "kubernetes_namespace" "default" {
  metadata {
    name = "default"
  }

  depends_on = []
}

# Enable Kubernetes Auth Backend in Vault
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

# Create a Service Account for Vault authentication
resource "kubernetes_service_account" "vault_auth" {
  metadata {
    name      = "vault-auth"
    namespace = "default"
  }

  depends_on = [data.kubernetes_namespace.default]
}

# Create ClusterRoleBinding for the Service Account
resource "kubernetes_cluster_role_binding" "vault_auth" {
  metadata {
    name = "role-tokenreview-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vault_auth.metadata[0].name
    namespace = kubernetes_service_account.vault_auth.metadata[0].namespace
  }

  depends_on = [kubernetes_service_account.vault_auth]
}

data "external" "vault_token_reviewer_jwt" {
  program = ["bash", "-c", <<-EOT
    kubectl create token vault-auth --duration=8760h | jq -nR '{ "token": input }'
  EOT
  ]

  depends_on = [kubernetes_service_account.vault_auth]
}

# Configure the Kubernetes Auth Backend in Vault
resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend             = vault_auth_backend.kubernetes.path
  kubernetes_host     = var.kubernetes_host
  kubernetes_ca_cert  = base64decode(var.cluster_ca_certificate)
  token_reviewer_jwt  = data.external.vault_token_reviewer_jwt.result["token"]
}

# Create a Vault policy for cert-manager
resource "vault_policy" "cert_manager" {
  name = "cert-manager"

  policy = <<EOF
path "${var.pki_int_path}/sign/${var.role_name}" {
  capabilities = ["update"]
}
EOF
}

# Create a Vault role for cert-manager
resource "vault_kubernetes_auth_backend_role" "cert_manager" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "cert-manager"
  bound_service_account_names      = ["cert-manager"]
  bound_service_account_namespaces = ["cert-manager"]
  token_policies                   = [vault_policy.cert_manager.name]
  token_ttl                        = 3600

  depends_on = [vault_policy.cert_manager]
}

# Check if the 'cert-manager' service account exists in the 'cert-manager' namespace
data "kubernetes_service_account_v1" "cert_manager" {
  metadata {
    name      = "cert-manager"
    namespace = "cert-manager"
  }
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [data.kubernetes_service_account_v1.cert_manager]

  create_duration = "30s"
}


# Create a Secret for the 'cert-manager' Service Account if it exists
# (TODO: replace with kubernetes provider as soon as it is possible)
resource "null_resource" "create_cert_manager_sa_secret" {
  depends_on = [time_sleep.wait_30_seconds]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f - <<EOF
      apiVersion: v1
      kind: Secret
      metadata:
        name: cert-manager
        namespace: cert-manager
        annotations:
          kubernetes.io/service-account.name: "cert-manager"
      type: kubernetes.io/service-account-token
      EOF
    EOT
  }
}
