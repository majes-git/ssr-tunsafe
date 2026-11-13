{% set tunsafe_config = "/etc/128technology/tunsafe/tunsafe.conf" %}
{% set sbin_path = "/usr/local/sbin" %}
{% set update_script = "update-tunsafe-config.bash" %}
{% set peers_config = "/var/lib/tunsafe/tunsafe.config" %}

Install config update script:
  file.managed:
    - name: "{{ sbin_path }}/{{ update_script }}"
    - mode: 755
    - source: salt://{{ update_script }}

Fetch peers config:
  file.managed:
    - name: "{{ peers_config }}"
    - mode: 755
    - source: salt://usermgr/tunsafe.config

Update tunsafe configuration:
  cmd.run:
    - name: "{{ sbin_path }}/{{ update_script }}"
    - onchanges:
      - file: Fetch peers config

Install cronjob:
  cron.present:
    - name: /usr/bin/salt-call state.apply update-tunsafe-config
    - user: root
    - hour: 1
    - minute: 0
