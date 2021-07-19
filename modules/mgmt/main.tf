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

resource "azurerm_linux_virtual_machine_scale_set" "mgmt_ss" {
  name                = "mgmt"
  resource_group_name = var.rg
  location            = var.location
  sku                 = "Standard_F2"
  instances           = 1
  admin_username      = var.username
  admin_password      = var.password
  disable_password_authentication = false
  custom_data = filebase64("scripts/mgmt-init.sh")

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "example"
    primary = true

    ip_configuration {
      name                                   = "mgmt_ipc"
      primary                                = true
      subnet_id                              = var.subnet
      public_ip_address {
        name              = "mgmt_ip"
      }
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "mgmg_settings" {
  name                = "mgmg_settings"
  resource_group_name = var.rg
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.mgmt_ss.id

  profile {
    name = "default"

    capacity {
      default = 1
      minimum = 1
      maximum = 1
    }
  }
}
