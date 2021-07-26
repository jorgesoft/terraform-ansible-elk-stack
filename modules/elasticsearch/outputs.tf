output "ips" {
  value = toset([
    for ip in azurerm_network_interface.es_nics : ip.private_ip_address
  ])
}