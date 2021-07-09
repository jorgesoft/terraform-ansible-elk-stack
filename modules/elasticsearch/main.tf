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

resource "azurerm_lb" "elastic_lb" {
  name                = "elastic_lb"
  location            = var.location
  resource_group_name = var.rg
  sku = "Standard"

  frontend_ip_configuration {
    name      = "esipconfig"
    subnet_id = var.subnet
  }
}

resource "azurerm_lb_backend_address_pool" "es_nodes" {
  name            = "esnodes"
  loadbalancer_id = azurerm_lb.elastic_lb.id
}

resource "azurerm_lb_backend_address_pool_address" "es_ips" {
  name                    = "esips"
  backend_address_pool_id = azurerm_lb_backend_address_pool.es_nodes.id
  virtual_network_id      = var.vnet
  ip_address              = "10.0.0.1"
}

locals {
  vms = ["elasticmaster", "elasticnode1", "elasticnode2"]
}
