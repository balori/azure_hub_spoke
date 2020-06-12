# Resource Group creation
resource "azurerm_resource_group" "k8s" {
  name     = var.rg-name
  location = var.location
}

resource "azurerm_resource_group" "dev_k8s" {
  name      = var.dev_rg-name
  location  = var.location
  providers = azurerm.dev
}


# AAD K8s Backend App

resource "azuread_application" "aks-aad-srv" {
  name                       = "${var.clustername}srv"
  homepage                   = "https://${var.clustername}srv"
  identifier_uris            = ["https://${var.clustername}srv"]
  reply_urls                 = ["https://${var.clustername}srv"]
  type                       = "webapp/api"
  group_membership_claims    = "All"
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = false
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access {
      id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
      type = "Role"
    }
    resource_access {
      id   = "06da0dbc-49e2-44d2-8312-53f166ab848a"
      type = "Scope"
    }
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }
  required_resource_access {
    resource_app_id = "00000002-0000-0000-c000-000000000000"
    resource_access {
      id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "aks-aad-srv" {
  application_id = azuread_application.aks-aad-srv.application_id
}

resource "random_password" "aks-aad-srv" {
  length  = 16
  special = true
}

resource "azuread_application_password" "aks-aad-srv" {
  application_object_id = azuread_application.aks-aad-srv.object_id
  value                 = random_password.aks-aad-srv.result
  end_date              = "2024-01-01T01:02:03Z"
}

# AAD AKS kubectl app

resource "azuread_application" "aks-aad-client" {
  name       = "${var.clustername}client"
  homepage   = "https://${var.clustername}client"
  reply_urls = ["https://${var.clustername}client"]
  type       = "native"
  required_resource_access {
    resource_app_id = azuread_application.aks-aad-srv.application_id
    resource_access {
      id   = azuread_application.aks-aad-srv.oauth2_permissions[0].id
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "aks-aad-client" {
  application_id = azuread_application.aks-aad-client.application_id
}

# AAD K8s cluster admin group / AAD

resource "azuread_group" "aks-aad-clusteradmins" {
  name = "${var.clustername}clusteradmin"
}

# Service principal for cluster
# first you need an azure application
resource "azuread_application" "aks_sp" {
  name                       = var.clustername
  homepage                   = "https://${var.clustername}"
  identifier_uris            = ["https://${var.clustername}"]
  reply_urls                 = ["https://${var.clustername}"]
  available_to_other_tenants = false # default
  public_client              = false # default
  oauth2_allow_implicit_flow = false # default
}

# service principal
resource "azuread_service_principal" "sp" {
  application_id               = azuread_application.aks_sp.application_id
  app_role_assignment_required = false # default
}

# create random password
resource "random_password" "aks_rnd_sp_pwd" {
  length  = 16
  special = true
}

resource "azuread_service_principal_password" "aks_sp_pwd" {
  service_principal_id = azuread_service_principal.sp.id
  value                = random_password.aks_rnd_sp_pwd.result
  end_date             = "2099-01-01T01:01:01Z"
}

resource "azurerm_role_assignment" "aks_sp_role_assignment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.sp.id

  depends_on = [
    azuread_service_principal_password.aks_sp_pwd
  ]
}

# Before giving consent, wait. Sometimes Azure returns a 200, but not all services have access to the newly created applications/services.

resource "null_resource" "delay_before_consent" {
  provisioner "local-exec" {
    command     = "start-sleep 60"
    interpreter = ["PowerShell", "-Command"]
  }
  depends_on = [
    azuread_service_principal.aks-aad-srv,
    azuread_service_principal.aks-aad-client
  ]
}

# Give admin consent - SP/az login user must be AAD admin

resource "null_resource" "grant_srv_admin_constent" {
  provisioner "local-exec" {
    command = "az ad app permission admin-consent --id ${azuread_application.aks-aad-srv.application_id}"
  }
  depends_on = [
    null_resource.delay_before_consent
  ]
}
resource "null_resource" "grant_client_admin_constent" {
  provisioner "local-exec" {
    command = "az ad app permission admin-consent --id ${azuread_application.aks-aad-client.application_id}"
  }
  depends_on = [
    null_resource.delay_before_consent
  ]
}

# Again, wait for a few seconds...

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command     = "start-sleep 60"
    interpreter = ["PowerShell", "-Command"]
  }
  depends_on = [
    null_resource.grant_srv_admin_constent,
    null_resource.grant_client_admin_constent
  ]
}


