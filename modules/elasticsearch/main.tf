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
  vms = ["elasticmaster", "elasticnode1", "elasticnode2"]
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
  for_each                = toset(var.vm_names)
  name                    = each.value
  backend_address_pool_id = azurerm_lb_backend_address_pool.es_nodes.id
  virtual_network_id      = var.vnet
  ip_address              = azurerm_network_interface.es_nics[each.key].private_ip_address
}

resource "azurerm_network_interface" "es_nics" {
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
  network_interface_ids = [azurerm_network_interface.es_nics[each.key].id]
  vm_size               = "Standard_B2s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

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