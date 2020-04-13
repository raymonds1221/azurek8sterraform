terraform {
  backend "azurerm" {
    access_key           = "${var.az_storage_access_key}"
    storage_account_name = "${var.storage_account_name}"
    container_name       = "${var.container_name}"
    key                  = "${var.key}"
  }
}

provider "vault" {}

resource "vault_generic_secret" "auth" {
  path = "kv/employerapi-test"

  # Sample data json of your secret:
  data_json = <<EOT
  {
    "username": "${var.username}",
    "password": "${var.password}",
    "access_key": "${var.access_key}",
    "key1": "${var.key1}"
  }
  EOT
}

resource "vault_policy" "this" {
  name = "employerapi"

  policy = <<EOT
path "kv/data/employerapi-test" {
  capabilities = ["read", "create", "update", "list"]
}
path "kv/data/employerapi-test/*" {
  capabilities = ["read", "create", "update", "list"]
}
path "kv/employerapi-test" {
  capabilities = ["read", "create", "update", "list"]
}
path "kv/employerapi-test/*" {
  capabilities = ["read", "create", "update", "list"]
}
path "sys/leases/renew" {
  capabilities = ["create"]
}
path "sys/leases/revoke" {
  capabilities = ["update"]
}
  EOT
}

resource "kubernetes_config_map" "hcl" {
  metadata {
    name      = "employerapi-config"
    namespace = "live"
  }

  data = {
    "vault-agent-config.hcl"     = "${file("./config/vault-agent-config.hcl")}"
    "consul-template-config.hcl" = "${file("./config/consul-template-config.hcl")}"
  }
}

resource "vault_kubernetes_auth_backend_config" "this" {
  backend            = "kubernetes"
  kubernetes_host    = "${var.kubernetes_host}"
  kubernetes_ca_cert = "${var.kubernetes_ca_cert}"
  token_reviewer_jwt = "${var.token_reviewer_jwt}"
}

resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = "kubernetes"
  role_name                        = "employerapi-test"
  bound_service_account_names      = ["employerapi-test"]
  bound_service_account_namespaces = ["live", "default"]

  token_policies = ["employerapi"]
  token_ttl      = 86400
}
