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

resource "azurerm_virtual_network" "elk_vnet" {
  name                = "elk_vnet"
  location            = var.location
  resource_group_name = var.rg
  address_space       = ["10.0.0.0/16"]
  #dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name           = "mgmt_sn"
    address_prefix = "10.0.1.0/24"
    #security_group = azurerm_network_security_group.mgmt_nsg.id
  }

  subnet {
    name           = "elastic_sn"
    address_prefix = "10.0.2.0/24"
    #security_group = azurerm_network_security_group.elastic_nsg.id
  }

  subnet {
    name           = "kibana_sn"
    address_prefix = "10.0.3.0/24"
    #security_group = azurerm_network_security_group.kibana_nsg.id
  }

  subnet {
    name           = "logstash_sn"
    address_prefix = "10.0.4.0/24"
  }

}
