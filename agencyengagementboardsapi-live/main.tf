terraform {
  backend "azurerm" {
    access_key           = "${var.az_storage_access_key}"
    storage_account_name = "${var.storage_account_name}"
    container_name       = "${var.container_name}"
    key                  = "${var.key}"
  }
}

# Vault

provider "vault" {}

resource "vault_generic_secret" "this" {
  path = "kv/agencyengagementboardsapi"

  data_json = <<EOT
  {
    "jwks_uri": "${var.jwks_uri}",
    "jwks_audience": "${var.jwks_audience}",
    "jwks_issuer": "${var.jwks_issuer}",
    "jwks_algorithm": "${var.jwks_algorithm}",
    "elastic_host": "${var.elastic_host}",
    "elastic_port": "${var.elastic_port}",
    "elasticsearch_auth_file": "${var.elasticsearch_auth_file}",
    "appinsights_instrumentation_key": "${var.appinsights_instrumentation_key}"
  }
  EOT
}

resource "vault_policy" "this" {
  name = "agencyengagementboardsapipolicy"

  policy = <<EOT
path "kv/agencyengagementboardsapi" {
  capabilities = ["read", "create"]
}
path "kv/agencyengagementboardsapi/*" {
  capabilities = ["read", "create"]
}
path "kv/data/agencyengagementboardsapi" {
  capabilities = ["read", "create"]
}
path "kv/data/agencyengagementboardsapi/*" {
  capabilities = ["read", "create"]
}
path "sys/leases/renew" {
  capabilities = ["create"]
}
path "sys/leases/revoke" {
  capabilities = ["update"]
}
  EOT
}

# Kubernetes

provider "kubernetes" {}

resource "kubernetes_config_map" "this" {
  metadata {
    name      = "agencyengagementboardsapi-config"
    namespace = "live"
  }

  data = {
    "vault-agent-config.hcl"     = "${file("./config/vault-agent-config.hcl")}"
    "consul-template-config.hcl" = "${file("./config/consul-template-config.hcl")}"
  }
}

resource "vault_kubernetes_auth_backend_config" "this" {
  backend            = "kubernetes"
  kubernetes_host    = "${var.k8s_host}"
  kubernetes_ca_cert = "${var.sa_ca_crt}"
  token_reviewer_jwt = "${var.sa_jwt_token}"
}

resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = "kubernetes"
  role_name                        = "agencyengagementboardsapi"
  bound_service_account_names      = ["agencyengagementboardsapi"]
  bound_service_account_namespaces = ["live"]
  token_policies                   = ["agencyengagementboardsapipolicy"]
  token_ttl                        = 86400
}
