terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "elk_rg" {
  name     = "elk_rg"
  location = "West US 2"
}

module "network" {
  source = "./modules/network"
  rg = azurerm_resource_group.elk_rg.name
  location = azurerm_resource_group.elk_rg.location
}

module "mgmt" {
  source = "./modules/mgmt"
  rg = azurerm_resource_group.elk_rg.name
  location = azurerm_resource_group.elk_rg.location
  subnet = module.network.elk_subnets[0]
  password = var.password
  username = var.username
}