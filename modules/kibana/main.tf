terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.67.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_public_ip" "kibana_ip" {
  name                = "kibanaIP"
  location            = var.location
  resource_group_name = var.rg
  sku = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_lb" "kibana_lb" {
  name                = "kibana_lb"
  location            = var.location
  resource_group_name = var.rg
  sku = "Standard"

  frontend_ip_configuration {
    name      = "kbipconfig"
    #subnet_id = var.subnet
    public_ip_address_id = azurerm_public_ip.kibana_ip.id
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
  loadbalancer_id                = azurerm_lb.kibana_lb.id
  name                           = "kibanarule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 5601
  frontend_ip_configuration_name = "kbipconfig"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.kb_nodes.id
  probe_id = azurerm_lb_probe.kibana_probe.id
}

resource "azurerm_lb_backend_address_pool" "kb_nodes" {
  name            = "kibananodes"
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
    admin_username      = var.username
    admin_password      = var.password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "azurerm_lb_outbound_rule" "example" {
  resource_group_name     = var.rg
  loadbalancer_id         = azurerm_lb.kibana_lb.id
  name                    = "KibanaOutbound"
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.kb_nodes.id

  frontend_ip_configuration {
    name = "kbipconfig"
  }
}
