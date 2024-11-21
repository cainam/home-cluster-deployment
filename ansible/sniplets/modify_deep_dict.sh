---
- hosts: localhost
  connection: local
  gather_facts: no

  vars:
    applications:
      istio-system:
        base:
          git: https://github.com/istio/istio.git
      istio-ingress:
        gateway:
          helm_options: --set 'service.externalIPs={"{{ load_balancer_ip }}"}'
      auth:
        oauth2-proxy:
          helm_options: --set proxyVarsAsSecrets=false
          files:
            config:
              file: oauth2-proxy-config.yaml
          network:
            svcPort: 80

  tasks:
    - name: Change
      set_fact:
        applications: "{{ applications|combine({'auth': {'oauth2-proxy': {'files': {'temp_file':'mytemp' } }}}, recursive=True) }}"

    - name: echo
      debug: var=applications

    - name: echo
      debug: var=applications['auth']
