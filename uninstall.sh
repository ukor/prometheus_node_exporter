#!/bin/bash

if [ $(id -u) -ne 0 ]; then
  echo "Run as root or with sudo"
  exit 1
fi

#
# TODO - warn the user that changes made by this script can not be undone
# TODO - provide a means to overide interactive mode
# TODO - collapse the redundant varibales names (Think about this)
#

USER="prometheus"

PROMETHEUS="prometheus"

NODE_EXPORTER="node_exporter"

NAME="prometheus"

rm -rf /opt/$NAME
rm -rf /etc/prometheus
rm -rf /var/lib/prometheus

systemctl stop $NODE_EXPORTER
systemctl disable $NODE_EXPORTER
rm /etc/systemd/system/$NODE_EXPORTER.service

systemctl stop $PROMETHEUS
systemctl disable $PROMETHEUS
rm /etc/systemd/system/$PROMETHEUS.service

systemctl daemon-reload

groupdel $USER
userdel --remove $USER

