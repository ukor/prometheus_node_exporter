# Prometheus and Node_exporter Automation

Installs Prometheus and node_exporter latest version on arm64 and x86_64

- Tested on Amazon Linux 2, ubuntu, Debian, CentOS7, CentOS8

## Requirements

- sudo privileges
- Environmental varaibles

```
GRAFANA_URL

GRAFANA_USERNAME

GRAFANA_PASSWORD
```

## Usage

Run the command with under `sudo` privilege in your linux server.

```bash
sh <(curl https://raw.githubusercontent.com/ukor/prometheus_node_exporter/master/installer.sh)
```

## Uninstall

To undo all the changes that was made by the installer, run this command

```bash
sh <(curl https://raw.githubusercontent.com/ukor/prometheus_node_exporter/master/uninstall.sh)
```

### Resources

- Monitoring a Linux host using Prometheus and node_exporter -
  https://grafana.com/docs/grafana-cloud/send-data/metrics/metrics-prometheus/prometheus-config-examples/noagent_linuxnode/

- Install Prometheus -
  https://www.cherryservers.com/blog/install-prometheus-ubuntu

- Grafana Agent with ansible -
  https://grafana.com/docs/grafana-cloud/developer-resources/infrastructure-as-code/ansible/ansible-grafana-agent-linux/
