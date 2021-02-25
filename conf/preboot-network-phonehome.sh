#!/bin/sh
# Run in ~chroot env on image creation
set -eu

# Populate known_hosts
mkdir -p /etc/phonehome
ssh -o UserKnownHostsFile=/etc/phonehome/known_hosts \
    -o StrictHostKeyChecking=accept-new \
    -o BatchMode=yes \
    phonehome@phonehome.tutor-web.net \
    /bin/true || true  # NB: We don't care if we actually connect
[ -f /etc/phonehome/known_hosts ] || exit 1
echo "" > /etc/phonehome/config

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
    -o UserKnownHostsFile=/etc/phonehome/known_hosts \
    -i /twpreload/phonehome/id_rsa \
    -L 9025:localhost:25 \
    -R /tmp/phonehome-%h:localhost:22 \
    -F /etc/phonehome/config \
    phonehome@phonehome.tutor-web.net

# Restart every >2 seconds to avoid StartLimitInterval failure
RestartSec=300
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable phonehome.service
