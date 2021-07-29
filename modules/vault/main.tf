terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "random_string" "vault_name" {
  length  = 6
  special = false
  upper   = false
  number  = true
}

resource "azurerm_key_vault" "elkvault" {
  name                            = random_string.vault_name.result
  location                        = var.location
  resource_group_name             = var.rg
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "premium"
  soft_delete_retention_days      = 7
  enabled_for_deployment          = true
  enabled_for_template_deployment = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "create",
      "get",
    ]

    secret_permissions = [
      "list",
      "set",
      "get",
      "delete",
      "purge",
      "recover"
    ]
  }
}

resource "azurerm_key_vault_secret" "elk_secret" {
  name         = "secret-sauce"
  value        = var.password
  key_vault_id = azurerm_key_vault.elkvault.id
}