output "logs_lb_ip" {
  value = azurerm_lb.logs_lb.private_ip_address
}

output "ips" {
  value = toset([
    for ip in azurerm_network_interface.logs_nics : ip.private_ip_address
  ])
}