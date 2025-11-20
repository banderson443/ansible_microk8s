ansible all -m ansible.builtin.shell -a "microk8s kubectl describe pod $1"
