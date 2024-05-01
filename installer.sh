#!/bin/bash

if [ $(id -u) -ne 0 ]; then
  echo "Run as root or with sudo"
  exit 1
fi

OSTYPE=$(uname -m)

if [ "${OSTYPE}" = "x86_64" ]; then
    BIN="amd64"
else
    BIN="arm64"
fi

USER="prometheus"

PROMETHEUS="prometheus"

NODE_EXPORTER="node_exporter"

NAME="prometheus"

mkdir /opt/$NAME
mkdir /opt/$NAME/bin
mkdir /etc/prometheus
mkdir /var/lib/prometheus

cd /tmp/

LATEST_PROMETHEUS=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "linux-${BIN}.tar.gz" | cut -d '"' -f 4 | tail -1)

curl -s -LJO $LATEST_PROMETHEUS

tar -zxf $PROMETHEUS-*.tar.gz

mv /tmp/$PROMETHEUS-*/prometheus /opt/$NAME/bin
mv /tmp/$PROMETHEUS-*/promtool /opt/$NAME/bin
mv /tmp/$PROMETHEUS-*/consoles /etc/prometheus
mv /tmp/$PROMETHEUS-*/console_libraries /etc/prometheus
# mv prometheus.yml /etc/prometheus


LATEST_NODE_EXPORTER=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep "linux-${BIN}.tar.gz" | cut -d '"' -f 4 | tail -1)

curl -s -LJO $LATEST_NODE_EXPORTER

tar -zxf $NODE_EXPORTER-*.tar.gz

mv /tmp/$NODE_EXPORTER-*/node_exporter /opt/$NAME/bin

cat << EOF > /etc/systemd/system/$PROMETHEUS.service
[Unit]
Description=Prometheus
Documentation=https://github.com/prometheus/prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=/opt/$NAME/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# TODO - check that the config file exist
#
. $HOME/grafana.confg


cat << EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 60s

scrape_configs:
  - job_name: node
    static_configs:
      - targets: ['localhost:9100']

remote_write:
  - url: $GRAFANA_URL 
    basic_auth:
      username: $GRAFANA_USERNAME
      password: $GRAFANA_PASSWORD
EOF


cat << EOF > /etc/systemd/system/$NODE_EXPORTER.service
[Unit]
Description=Prometheus exporter for machine metrics
Documentation=https://github.com/prometheus/node_exporter

[Service]
Restart=always
User=$USER
Group=$USER
EnvironmentFile=/opt/$NAME/node_exporter_env
ExecStart=/opt/$NAME/bin \$ARGS
ExecReload=/bin/kill -HUP $MAINPID
TimeoutStopSec=20s
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /opt/$NAME/node_exporter_env
# Set the command-line arguments to pass to the server.
# Due to shell scaping, to pass backslashes for regexes, you need to double
# them (\\d for \d). If running under systemd, you need to double them again
# (\\\\d to mean \d), and escape newlines too.
ARGS=""

# Prometheus-node-exporter supports the following options:
#
#  --collector.diskstats.ignored-devices="^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$"
#                            Regexp of devices to ignore for diskstats.
#  --collector.filesystem.ignored-mount-points="^/(dev|proc|run|sys|mnt|media|var/lib/docker)($|/)"
#                            Regexp of mount points to ignore for filesystem
#                            collector.
#  --collector.filesystem.ignored-fs-types="^(autofs|binfmt_misc|cgroup|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|sysfs|tracefs)$"
#                            Regexp of filesystem types to ignore for
#                            filesystem collector.
#  --collector.netdev.ignored-devices="^lo$"
#                            Regexp of net devices to ignore for netdev
#                            collector.
#  --collector.netstat.fields="^(.*_(InErrors|InErrs)|Ip_Forwarding|Ip(6|Ext)_(InOctets|OutOctets)|Icmp6?_(InMsgs|OutMsgs)|TcpExt_(Listen.*|Syncookies.*)|Tcp_(ActiveOpens|PassiveOpens|RetransSegs|CurrEstab)|Udp6?_(InDatagrams|OutDatagrams|NoPorts))$"
#                            Regexp of fields to return for netstat
#                            collector.
#  --collector.ntp.server="127.0.0.1"
#                            NTP server to use for ntp collector
#  --collector.ntp.protocol-version=4
#                            NTP protocol version
#  --collector.ntp.server-is-local
#                            Certify that collector.ntp.server address is the
#                            same local host as this collector.
#  --collector.ntp.ip-ttl=1  IP TTL to use while sending NTP query
#  --collector.ntp.max-distance=3.46608s
#                            Max accumulated distance to the root
#  --collector.ntp.local-offset-tolerance=1ms
#                            Offset between local clock and local ntpd time
#                            to tolerate
#  --path.procfs="/proc"     procfs mountpoint.
#  --path.sysfs="/sys"       sysfs mountpoint.
#  --collector.qdisc.fixtures=""
#                            test fixtures to use for qdisc collector
#                            end-to-end testing
#  --collector.runit.servicedir="/etc/service"
#                            Path to runit service directory.
#  --collector.supervisord.url="http://localhost:9001/RPC2"
#                            XML RPC endpoint.
#  --collector.systemd.unit-whitelist=".+"
#                            Regexp of systemd units to whitelist. Units must
#                            both match whitelist and not match blacklist to
#                            be included.
#  --collector.systemd.unit-blacklist=".+(\\.device|\\.scope|\\.slice|\\.target)"
#                            Regexp of systemd units to blacklist. Units must
#                            both match whitelist and not match blacklist to
#                            be included.
#  --collector.systemd.private
#                            Establish a private, direct connection to
#                            systemd without dbus.
#  --collector.textfile.directory="/var/lib/prometheus/node-exporter"
#                            Directory to read text files with metrics from.
#  --collector.vmstat.fields="^(oom_kill|pgpg|pswp|pg.*fault).*"
#                            Regexp of fields to return for vmstat collector.
#  --collector.wifi.fixtures=""
#                            test fixtures to use for wifi collector metrics
#  --collector.arp           Enable the arp collector (default: enabled).
#  --collector.bcache        Enable the bcache collector (default: enabled).
#  --collector.bonding       Enable the bonding collector (default: enabled).
#  --collector.buddyinfo     Enable the buddyinfo collector (default:
#                            disabled).
#  --collector.conntrack     Enable the conntrack collector (default:
#                            enabled).
#  --collector.cpu           Enable the cpu collector (default: enabled).
#  --collector.diskstats     Enable the diskstats collector (default:
#                            enabled).
#  --collector.drbd          Enable the drbd collector (default: disabled).
#  --collector.edac          Enable the edac collector (default: enabled).
#  --collector.entropy       Enable the entropy collector (default: enabled).
#  --collector.filefd        Enable the filefd collector (default: enabled).
#  --collector.filesystem    Enable the filesystem collector (default:
#                            enabled).
#  --collector.hwmon         Enable the hwmon collector (default: enabled).
#  --collector.infiniband    Enable the infiniband collector (default:
#                            enabled).
#  --collector.interrupts    Enable the interrupts collector (default:
#                            disabled).
#  --collector.ipvs          Enable the ipvs collector (default: enabled).
#  --collector.ksmd          Enable the ksmd collector (default: disabled).
#  --collector.loadavg       Enable the loadavg collector (default: enabled).
#  --collector.logind        Enable the logind collector (default: disabled).
#  --collector.mdadm         Enable the mdadm collector (default: enabled).
#  --collector.meminfo       Enable the meminfo collector (default: enabled).
#  --collector.meminfo_numa  Enable the meminfo_numa collector (default:
#                            disabled).
#  --collector.mountstats    Enable the mountstats collector (default:
#                            disabled).
#  --collector.netdev        Enable the netdev collector (default: enabled).
#  --collector.netstat       Enable the netstat collector (default: enabled).
#  --collector.nfs           Enable the nfs collector (default: enabled).
#  --collector.nfsd          Enable the nfsd collector (default: enabled).
#  --collector.ntp           Enable the ntp collector (default: disabled).
#  --collector.qdisc         Enable the qdisc collector (default: disabled).
#  --collector.runit         Enable the runit collector (default: disabled).
#  --collector.sockstat      Enable the sockstat collector (default:
#                            enabled).
#  --collector.stat          Enable the stat collector (default: enabled).
#  --collector.supervisord   Enable the supervisord collector (default:
#                            disabled).
#  --collector.systemd       Enable the systemd collector (default: enabled).
#  --collector.tcpstat       Enable the tcpstat collector (default:
#                            disabled).
#  --collector.textfile      Enable the textfile collector (default:
#                            enabled).
#  --collector.time          Enable the time collector (default: enabled).
#  --collector.uname         Enable the uname collector (default: enabled).
#  --collector.vmstat        Enable the vmstat collector (default: enabled).
#  --collector.wifi          Enable the wifi collector (default: enabled).
#  --collector.xfs           Enable the xfs collector (default: enabled).
#  --collector.zfs           Enable the zfs collector (default: enabled).
#  --collector.timex         Enable the timex collector (default: enabled).
#  --web.listen-address=":9100"
#                            Address on which to expose metrics and web
#                            interface.
#  --web.telemetry-path="/metrics"
#                            Path under which to expose metrics.
#  --log.level="info"        Only log messages with the given severity or
#                            above. Valid levels: [debug, info, warn, error,
#                            fatal]
#  --log.format="logger:stderr"
#                            Set the log target and format. Example:
#                            "logger:syslog?appname=bob&local=7" or
#                            "logger:stdout?json=true"
EOF


addgroup $USER
adduser --system --home /opt/$NAME $USER --shell /sbin/nologin --gid $USER

chown --recursive $USER:$USER /opt/$NAME

chown --recursive $USER:$USER /etc/prometheus
chown --recursive $USER:$USER /etc/prometheus/consoles
chown --recursive $USER:$USER /etc/prometheus/console_libraries
chown --recursive $USER:$USER /var/lib/prometheus

systemctl enable $NODE_EXPORTER
systemctl start $NODE_EXPORTER
systemctl status $NODE_EXPORTER

systemctl enable $PROMETHEUS
systemctl start $PROMETHEUS
systemctl status $PROMETHEUS

rm -rf /tmp/$PROMETHEUS-*

rm -rf /tmp/$NODE_EXPORTER-*

systemctl daemon-relaod

