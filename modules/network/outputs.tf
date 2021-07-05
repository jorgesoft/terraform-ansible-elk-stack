output "elk_vnet_name" {
  value = azurerm_virtual_network.elk_vnet.name
}

output "elk_subnets" {
  value = azurerm_virtual_network.elk_vnet.subnet.*.id
}