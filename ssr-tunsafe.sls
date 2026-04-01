{% set repo_url = "https://github.com/majes-git/ssr-tunsafe" %}
{% set sbin_path = "/usr/local/sbin" %}
{% set base_dir = "/etc/128technology/plugins/network-scripts/host" %}
{% set target_dir = "/etc/128technology/plugins/network-scripts/default/kni_namespace" %}
{% set interface = "tunsafe" %}
{% set interface_dir = base_dir ~ "/" ~ interface %}
{% set interface_config = "/var/lib/128technology/kni/host/" ~ interface ~ ".conf" %}
{% set service_name = "ssr-tunsafe" %}
{% set tunsafe_config = "/etc/128technology/tunsafe/tunsafe.conf" %}

Install tunsafe binary:
  file.managed:
    - name: "{{ sbin_path }}/tunsafe"
    - mode: 755
    - source: salt://tunsafe

Create {{ interface_dir }}:
  file.directory:
    - name: {{ interface_dir }}
    - mode: 755
    - makedirs: True

{% for script in ["init", "startup", "shutdown"] %}
Install {{ script }} symlink for interface {{ interface }}:
  file.symlink:
    - name: {{ interface_dir }}/{{ script }}
    - target: {{ target_dir }}/{{ script }}
{% endfor %}

Install monitoring script for interface {{ interface }}:
  file.managed:
    - name: "{{ interface_dir }}/monitoring"
    - mode: 755
    - contents: |
        #!/bin/sh
        ip netns exec tunsafe ip link show dev tun0 >&- 2>&- && echo UP || echo DOWN

Generate interface config:
  file.managed:
    - name: {{ interface_config }}
    - contents: |
        routing:
            - "default dev {kni_interface} via {kni_gateway}"

Install {{ service_name }} service file:
  file.managed:
    - name: /etc/systemd/system/{{ service_name }}.service
    - contents: |
        [Unit]
        Description=Tunsafe daemon for Session Smart Router
        After=128T.service
        Requires=128T.service

        [Service]
        ExecStartPre=/usr/sbin/ip netns exec {{ interface }} true
        ExecStart=/usr/sbin/ip netns exec {{ interface }} {{ sbin_path }}/tunsafe start {{ tunsafe_config }}
        Restart=on-failure
        RestartSec=5

        [Install]
        WantedBy=multi-user.target

systemd-daemon-reload:
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: /etc/systemd/system/{{ service_name }}.service

{{ service_name }}:
  service.running:
    - enable: True
    - watch:
      - file: /etc/systemd/system/{{ service_name }}.service
    - require:
      - cmd: systemd-daemon-reload
