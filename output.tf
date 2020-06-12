# Output
output "server-app-id" {
  value = azuread_application.aks-aad-srv.application_id
}

output "client-app-id" {
  value = azuread_application.aks-aad-client.application_id
}

