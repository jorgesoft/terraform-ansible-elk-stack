terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.67.0"
    }
  }
  backend "remote" {
    organization = "jorgesoft"
    workspaces {
      name = "terrafor-ansible-elk-stack"
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
  source   = "./modules/network"
  rg       = azurerm_resource_group.elk_rg.name
  location = azurerm_resource_group.elk_rg.location
}

# module "vault" {
#   source   = "./modules/vault"
#   rg       = azurerm_resource_group.elk_rg.name
#   location = azurerm_resource_group.elk_rg.location
#   password = var.password
# }

module "mgmt" {
  source   = "./modules/mgmt"
  rg       = azurerm_resource_group.elk_rg.name
  location = azurerm_resource_group.elk_rg.location
  subnet   = module.network.elk_subnets[0]
  password = var.password
  username = var.username
}

module "elasticsearch" {
  source   = "./modules/elasticsearch"
  rg       = azurerm_resource_group.elk_rg.name
  location = azurerm_resource_group.elk_rg.location
  subnet   = module.network.elk_subnets[1]
  password = var.password
  username = var.username
  vnet     = module.network.elk_vnet_id
}

module "kibana" {
  source   = "./modules/kibana"
  rg       = azurerm_resource_group.elk_rg.name
  location = azurerm_resource_group.elk_rg.location
  subnet   = module.network.elk_subnets[2]
  password = var.password
  username = var.username
  vnet     = module.network.elk_vnet_id
}

module "nsgs" {
  source          = "./modules/nsgs"
  rg              = azurerm_resource_group.elk_rg.name
  location        = azurerm_resource_group.elk_rg.location
  mgmt_subnet     = module.network.elk_subnets[0]
  elastic_subnet  = module.network.elk_subnets[1]
  kibana_subnet   = module.network.elk_subnets[2]
  logstash_subnet = module.network.elk_subnets[3]
}