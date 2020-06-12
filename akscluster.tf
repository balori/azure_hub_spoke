# K8s cluster

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.clustername}"
  location            = "${var.location}"
  resource_group_name = "${var.rg-name}"
  dns_prefix          = "${var.clustername}"

  default_node_pool {
    name            = "default"
    type            = "VirtualMachineScaleSets"
    node_count      = 2
    vm_size         = "Standard_B2s"
    os_disk_size_gb = 30
    max_pods        = 50
  }
  service_principal {
    client_id     = "${azuread_application.aks_sp.application_id}"
    client_secret = "${random_password.aks_sp_pwd.result}"
  }
  role_based_access_control {
    azure_active_directory {
      client_app_id     = "${azuread_application.aks-aad-client.application_id}"
      server_app_id     = "${azuread_application.aks-aad-srv.application_id}"
      server_app_secret = "${random_password.aks-aad-srv.result}"
      tenant_id         = "${data.azurerm_subscription.current.tenant_id}"
    }
    enabled = true
  }
  depends_on = [
    null_resource.delay,
    azuread_service_principal.aks-aad-srv,
    azurerm_role_assignment.aks_sp_role_assignment,
    azuread_service_principal_password.aks_sp_pwd
  ]
}

# Role assignment

# User ADMIN credentials

provider "kubernetes" {
  host                   = "${azurerm_kubernetes_cluster.aks.kube_admin_config.0.host}"
  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)}"
}

# Cluster role binding to AAD group


resource "kubernetes_cluster_role_binding" "aad_integration" {
  metadata {
    name = "${var.clustername}admins"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind = "Group"
    name = "${azuread_group.aks-aad-clusteradmins.id}"
  }
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}