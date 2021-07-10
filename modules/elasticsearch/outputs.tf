output "es_lb_ip" {
  value = azurerm_lb.elastic_lb.private_ip_address
}

output "ips" {
  value = toset([
    for ip in azurerm_network_interface.es_nics : ip.private_ip_address
  ])
}