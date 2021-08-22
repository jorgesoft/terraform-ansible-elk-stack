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

resource "azurerm_network_interface" "logs_nics" {
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

resource "azurerm_network_interface_backend_address_pool_association" "logsIP_as" {
  for_each                = toset(var.vm_names)
  network_interface_id    = azurerm_network_interface.logs_nics[each.key].id
  ip_configuration_name   = each.value
  backend_address_pool_id = azurerm_lb_backend_address_pool.logstashPool.id
}

resource "azurerm_availability_set" "logs_av" {
  name                = "logsAV"
  location            = var.location
  resource_group_name = var.rg
}

resource "azurerm_virtual_machine" "main" {
  for_each              = toset(var.vm_names)
  name                  = each.value
  location              = var.location
  resource_group_name   = var.rg
  network_interface_ids = [azurerm_network_interface.logs_nics[each.key].id]
  vm_size               = "Standard_B2s"
  availability_set_id   = azurerm_availability_set.logs_av.id

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
    #custom_data   = filebase64("scripts/nginx.sh")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "random_string" "fqdn" {
  length  = 6
  special = false
  upper   = false
  number  = false
}

resource "azurerm_public_ip" "logsIP" {
  name                = "logsIP"
  location            = var.location
  resource_group_name = var.rg
  allocation_method   = "Static"
  domain_name_label   = random_string.fqdn.result
}

resource "azurerm_lb" "logs_lb" {
  name                = "logs_lb"
  location            = var.location
  resource_group_name = var.rg

  frontend_ip_configuration {
    name                 = "logsIP"
    public_ip_address_id = azurerm_public_ip.logsIP.id
  }
}

resource "azurerm_lb_backend_address_pool" "logstashPool" {
  loadbalancer_id     = azurerm_lb.logs_lb.id
  name                = "logstashPool"
}

resource "azurerm_lb_probe" "logsPr" {
  resource_group_name = var.rg
  loadbalancer_id     = azurerm_lb.logs_lb.id
  name                = "logsPr"
  port                = 5044
}

resource "azurerm_lb_rule" "logs_rule" {
  resource_group_name            = var.rg
  loadbalancer_id                = azurerm_lb.logs_lb.id
  name                           = "beats"
  protocol                       = "Tcp"
  frontend_port                  = 5044
  backend_port                   = 5044
  backend_address_pool_id        = azurerm_lb_backend_address_pool.logstashPool.id
  frontend_ip_configuration_name = "logsIP"
  probe_id                       = azurerm_lb_probe.logsPr.id
  load_distribution              = "SourceIPProtocol"
  idle_timeout_in_minutes        = 30
}
