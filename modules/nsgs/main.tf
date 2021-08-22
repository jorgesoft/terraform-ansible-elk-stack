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

# MGMT NSG
resource "azurerm_network_security_group" "mgmt_nsg" {
  name                = "mgmt_nsg"
  location            = var.location
  resource_group_name = var.rg

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet_network_security_group_association" "mgmt_nsg_subnet" {
  subnet_id                 = var.mgmt_subnet
  network_security_group_id = azurerm_network_security_group.mgmt_nsg.id
}

# Elastic NSG
resource "azurerm_network_security_group" "elastic_nsg" {
  name                = "elastic_nsg"
  location            = var.location
  resource_group_name = var.rg

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Elastic9200"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9200"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Elastic9300"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9300"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet_network_security_group_association" "elastic_nsg_subnet" {
  subnet_id                 = var.elastic_subnet
  network_security_group_id = azurerm_network_security_group.elastic_nsg.id
}

# Kibana NSG
resource "azurerm_network_security_group" "kibana_nsg" {
  name                = "kibana_nsg"
  location            = var.location
  resource_group_name = var.rg

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Kibana"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5601"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet_network_security_group_association" "kibana_nsg_subnet" {
  subnet_id                 = var.kibana_subnet
  network_security_group_id = azurerm_network_security_group.kibana_nsg.id
}