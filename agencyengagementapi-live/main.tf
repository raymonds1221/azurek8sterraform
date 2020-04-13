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
  path = "kv/agencyengagementapi"

  data_json = <<EOT
  {
    "azure_sql_username": "${var.azure_sql_username}",
    "azure_sql_password": "${var.azure_sql_password}",
    "service_bus_agency_engagement_connection_string": "${var.service_bus_agency_engagement_connection_string}",
    "service_bus_employer_notification_connection_string": "${var.service_bus_employer_notification_connection_string}",
    "service_bus_employer_emailalert_connection_string": "${var.service_bus_employer_emailalert_connection_string}"
  }
  EOT
}

resource "vault_policy" "this" {
  name = "agencyengagementapipolicy"

  policy = <<EOT
path "kv/data/agencyengagementapi" {
  capabilities = ["read", "create", "update", "list"]
}
path "kv/data/agencyengagementapi/*" {
  capabilities = ["read", "create", "update", "list"]
}
path "kv/agencyengagementapi" {
  capabilities = ["read", "create", "update", "list"]
}
path "kv/agencyengagementapi/*" {
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

provider "kubernetes" {}

resource "kubernetes_config_map" "hcl" {
  metadata {
    name      = "agencyengagementapi-config"
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
  role_name                        = "agencyengagementapi"
  bound_service_account_names      = ["agencyengagementapi"]
  bound_service_account_namespaces = ["live", "default"]

  token_policies = ["agencyengagementapipolicy"]
  token_ttl      = 86400
}
