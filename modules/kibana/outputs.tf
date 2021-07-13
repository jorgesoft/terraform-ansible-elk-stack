output "kb_lb_ip" {
  value = azurerm_lb.kibana_lb.private_ip_address
}

output "ips" {
  value = toset([
    for ip in azurerm_network_interface.kb_nics : ip.private_ip_address
  ])
}