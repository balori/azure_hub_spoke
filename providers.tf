provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.0.0"
  subscription_id = "6e73035c-42f3-42be-8ec4-b76e1e6d254c"
  features {}
}

provider "azurerm" {
  version         = "=2.0.0"
  subscription_id = "fb069fe7-53cc-47ef-a84c-04d15097287a"
  alias           = "dev"
  features {}
}

provider "azuread" {
  version = "~> 0.7"
}

terraform {
  backend "azurerm" {
    resource_group_name  = "FirstTerraformGroup"
    storage_account_name = "mritfstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

