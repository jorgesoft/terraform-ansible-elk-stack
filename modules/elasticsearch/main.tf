terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.67.0"
    }
  }
}

provider "azurerm" {
  features {}
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
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
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
    admin_username = var.username
    admin_password = var.password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "azurerm_network_security_group" "elastic_nsg" {
  name                = "elastic_nsg"
  location            = var.location
  resource_group_name = var.rg

  security_rule {
    name                       = "elasticIN"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "9200"
    destination_port_range     = "9200"
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