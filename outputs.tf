output "elasticelk_subnets_vms" {
    value = module.network.elk_subnets
}

output "es_ips" {
    value = module.elasticsearch.ips
}