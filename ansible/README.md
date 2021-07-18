to run elastic:
ansible-playbook elastic.yml -i hosts -k -u "jorges" 

to run kibana:
ansible-playbook kibana.yml -i hosts -k -K -b -u "jorges"