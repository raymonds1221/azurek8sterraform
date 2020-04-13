vault {
  renew_token            = false
  vault_agent_token_file = "/home/vault/.vault-token"

  retry {
    backoff = "1s"
  }
}

template {
  destination = "/etc/secrets/connectioninfo.json"

  contents = <<EOF
  {
    "ConnectionInfo": {
  {{- with secret "kv/data/agencyapi" }}
      "UbidyServicesAgenciesDatabase": {
        "Host": "ubidyaustraliaeastprod.database.windows.net",
        "AgenciesDatabaseName": "UbidyServicesAgenciesDatabase",
        "ApplicationsDatabaseName": "UbidyServicesApplicationsDatabase",
        "Port": "1433",
        "Username":"{{ .Data.data.azure_sql_username }}",
        "Password":"{{ .Data.data.azure_sql_password }}"
      },
      "AzureStorage": {
        "AccountName": "{{ .Data.data.azure_storage_account_name }}",
        "AccountKey": "{{ .Data.data.azure_storage_account_key }}"
      },
      "ServiceBusAgencyEngagementConnectionString": "{{ .Data.data.agency_engagement_connection_string }}"
  {{ end }}
    }
  }
  EOF
}
