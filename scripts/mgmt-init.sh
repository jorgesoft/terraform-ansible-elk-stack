#!/bin/bash

git clone https://github.com/jorgesoft/terraform-ansible-elk-stack.git
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y
sudo apt install sshpass -y
ansible-galaxy install elastic.elasticsearch,v7.14.0
ansible-galaxy install elastic.beats,v7.14.0
