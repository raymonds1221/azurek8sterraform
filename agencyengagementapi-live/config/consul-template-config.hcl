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
      "UbidyServicesEngagementDatabase": {
        "Host": "ubidyaustraliaeastprod.database.windows.net",
        "DatabaseName": "UbidyServicesAgencyEngagementDatabase",
        "Port": "1433",
        "Username":"{{ .Data.data.azure_sql_username }}",
        "Password":"{{ .Data.data.azure_sql_password }}"
      },
      "ServiceBusConnectionString": "{{ .Data.data.service_bus_agency_engagement_connection_string }}",
      "ServiceBusEmployerNotificationConnectionString": "{{ .Data.data.service_bus_employer_notification_connection_string }}",
      "ServiceBusEmployerEmailAlertConnectionString": "{{ .Data.data.service_bus_employer_emailalert_connection_string }}"
  {{ end }}
    }
  }
  EOF
}
