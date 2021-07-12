# Deploy ELK Stack on Azure with Terraform, Ansible, and GitHub Actions
Terraform configuration to deploy infrastructure in Azure. Ansible configuration to provision ELK stack in the resources. Everything automated with GitHub Actions.

## Terraform:
Terraform deploys the following modules within a single resource group:

- Elasticsearch: 
  - 3 VMs (one master and 2 nodes) Standard_B2s
  - 1 Load Balancer
- Kibana
  - 2 VMs for redundancy, Standard_B2s
  - 1 Load Balancer
- Logstash
  - 2 VMs for redundancy, Standard_B2s
  - 1 Load Balancer
- MGMT
  - 1 autoscaling VM, with Ansible to provision the resources
- Network
  - 1 VNET
  - 1 Subnet for each service (Elasticsearch, Kibana, Logstash, MGMT)
  - Network Security Groups to only allow required access for each service

Future releases planned modules: 
- Kafka

**WARNING:** The estimated price of this configuration is X monthly

## Ansible

TODO

## GitHub Actions

TODO