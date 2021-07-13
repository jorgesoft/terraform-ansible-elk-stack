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

locals {
  vms = ["kibana1", "kibana2"]
}

resource "azurerm_public_ip" "kibana_ip" {
  name                = "kibanaIP"
  location            = var.location
  resource_group_name = var.rg
  allocation_method   = "Static"
}

resource "azurerm_lb" "kibana_lb" {
  name                = "kibana_lb"
  location            = var.location
  resource_group_name = var.rg
  sku = "Standard"

  frontend_ip_configuration {
    name      = "kbipconfig"
    subnet_id = var.subnet
    public_ip_address_id = azurerm_public_ip.kibana_lb.id
  }
}

resource "azurerm_lb_probe" "kibana_probe" {
  resource_group_name = var.rg
  loadbalancer_id     = azurerm_lb.kibana_lb.id
  name                = "kibana_probe"
  port                = 5601
}

resource "azurerm_lb_rule" "kibanarule" {
  resource_group_name            = var.rg
  loadbalancer_id                = azurerm_lb.elastic_lb.id
  name                           = "kibanarule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 5601
  frontend_ip_configuration_name = "kbipconfig"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.kb_nodes.id
  probe_id = azurerm_lb_probe.kibana_probe.id
}

resource "azurerm_lb_backend_address_pool" "kb_nodes" {
  name            = "esnodes"
  loadbalancer_id = azurerm_lb.kibana_lb.id
}

resource "azurerm_lb_backend_address_pool_address" "kb_ips" {
  for_each                = toset(var.vm_names)
  name                    = each.value
  backend_address_pool_id = azurerm_lb_backend_address_pool.kb_nodes.id
  virtual_network_id      = var.vnet
  ip_address              = azurerm_network_interface.kb_nics[each.key].private_ip_address
}

resource "azurerm_network_interface" "kb_nics" {
  for_each            = toset(var.vm_names)
  name                = each.value
  location            = var.location
  resource_group_name = var.rg

  ip_configuration {
    name                          = each.value
    subnet_id                     = var.subnet
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  for_each              = toset(var.vm_names)
  name                  = each.value
  location              = var.location
  resource_group_name   = var.rg
  network_interface_ids = [azurerm_network_interface.kb_nics[each.key].id]
  vm_size               = "Standard_B2s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = each.value
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = each.value
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "azurerm_network_security_group" "kibana_nsg" {
  name                = "kibana_nsg"
  location            = var.location
  resource_group_name = var.rg

  security_rule {
    name                       = "kibanaIN"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "5601"
    destination_port_range     = "5601"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
}

#resource "azurerm_network_interface_security_group_association" "elastic_nsg_as" {
#  for_each              = toset(var.vm_names)
#  network_interface_id      = each.value
#  network_security_group_id = azurerm_network_security_group.example.id
#}