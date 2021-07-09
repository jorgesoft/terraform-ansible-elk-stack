output "elk_vnet_name" {
  value = azurerm_virtual_network.elk_vnet.name
}

output "elk_vnet_id" {
  value = azurerm_virtual_network.elk_vnet.id
}

output "elk_subnets" {
  value = azurerm_virtual_network.elk_vnet.subnet.*.id
}