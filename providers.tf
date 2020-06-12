provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.0.0"
  subscription_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
  features {}
}

provider "azurerm" {
  version         = "=2.0.0"
  subscription_id = "fxxxxxxxxxxxxxxxxxx"
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

