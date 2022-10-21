# notes on this ansible playbook

Usage example: 
    # ansible-playbook  -i $PWD/inventory $PWD/site.yml --skip-tags k8s_images

Notes:
- trying to run on one host only using run_once/delegate_to did only work having a hostname set as fact not with a variable. It seems like vars are re-evaluated when accessed, but facts remain constant
