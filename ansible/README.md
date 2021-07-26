ansible-playbook -i hosts ./elasticsearch.yml --ask-pass -u "jorges"
ansible-playbook -i hosts ./site.yml -k -K -u "jorges"
export ANSIBLE_HOST_KEY_CHECKING=False