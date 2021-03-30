#!/bin/sh
# Run in ~chroot env on image creation
set -eu

# Populate known_hosts, checking we can connect in the process
chmod a+r /twpreload/phonehome/id_rsa
mkdir -p /etc/phonehome
ssh -o UserKnownHostsFile=/etc/phonehome/known_hosts \
    -i /twpreload/phonehome/id_rsa \
    -F /twpreload/phonehome/config \
    -o StrictHostKeyChecking=accept-new \
    -o BatchMode=yes \
    phonehome /bin/true
[ -f /etc/phonehome/known_hosts ] || exit 1

cat <<'EOF' > /etc/systemd/system/phonehome.service
[Unit]
Description=Phone Home Reverse SSH Service
ConditionPathExists=|/usr/bin
After=network.target

[Service]
User=nobody
Type=simple
ExecStart=/usr/bin/ssh -NTC \
    -o ServerAliveInterval=60 \
    -o ExitOnForwardFailure=yes \
    -o StreamLocalBindUnlink=yes \
    -o UserKnownHostsFile=/etc/phonehome/known_hosts \
    -i /twpreload/phonehome/id_rsa \
    -L 9025:localhost:25 \
    -R /tmp/phonehome-%H-%m:localhost:22 \
    -F /twpreload/phonehome/config \
    phonehome

# Restart every >2 seconds to avoid StartLimitInterval failure
RestartSec=300
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable phonehome.service
