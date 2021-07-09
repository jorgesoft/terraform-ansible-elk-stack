output "es_lb_ip" {
  value = azurerm_lb.elastic_lb.private_ip_address
}

output "names" {
  value = null_resource.names
}