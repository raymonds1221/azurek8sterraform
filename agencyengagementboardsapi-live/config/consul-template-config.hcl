vault {
  renew_token            = false
  vault_agent_token_file = "/home/vault/.vault-token"

  retry {
    backoff = "1s"
  }
}

template {
  destination = "/etc/secrets/.env"

  contents = <<EOF
{{- with secret "kv/data/agencyengagementboardsapi" }}
ENV=production
PORT=80
JWKS_URI={{ .Data.data.jwks_uri }}
JWKS_AUDIENCE={{ .Data.data.jwks_audience }}
JWKS_ISSUER={{ .Data.data.jwks_issuer }}
JWKS_ALGORITHM={{ .Data.data.jwks_algorithm }}
ELASTIC_HOST={{ .Data.data.elastic_host }}
ELASTIC_PORT={{ .Data.data.elastic_port }}
ELASTICSEARCH_AUTH_FILE=Basic {{ .Data.data.elasticsearch_auth_file }}
APPINSIGHTS_INSTRUMENTATION_KEY={{ .Data.data.appinsights_instrumentation_key }}
{{ end }} 
EOF
}
