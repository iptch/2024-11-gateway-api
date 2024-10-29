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

# Ensure OIDC endpoints are unauthenticated
resource "kubernetes_cluster_role_binding_v1" "oidc_unauthenticated" {
  metadata {
    name = "service-account-issuer-discovery-unauthenticated"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:service-account-issuer-discovery"
  }
  subject {
    kind      = "Group"
    name      = "system:unauthenticated"
    api_group = "rbac.authorization.k8s.io"
  }
}

# enable JWKS authentication to validate K8s SAs
resource "vault_jwt_auth_backend" "kubernetes" {
  depends_on   = [kubernetes_cluster_role_binding_v1.oidc_unauthenticated]
  path         = "jwt"
  bound_issuer = "https://kubernetes.default.svc.cluster.local"
  jwks_url     = "${var.kubernetes_host}/openid/v1/jwks"
  jwks_ca_pem  = base64decode(var.cluster_ca_certificate)
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

resource "vault_jwt_auth_backend_role" "cert_manager" {
  backend        = vault_jwt_auth_backend.kubernetes.path
  role_name      = "cert-manager"
  token_policies = [vault_policy.cert_manager.name]
  token_ttl      = 15

  bound_audiences = ["vault://vault-issuer"]
  bound_subject   = "system:serviceaccount:cert-manager:cert-manager"
  user_claim      = "sub"
  role_type       = "jwt"
}
