#!/bin/sh -eu
# Run in ~chroot env on image creation

mkdir /etc/phonehome
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
    -o UserKnownHostsFile=/run/phonehome/known_hosts \
    -i /run/phonehome/id_rsa \
    -F /run/phonehome/config \
    phonehome

# Restart every >2 seconds to avoid StartLimitInterval failure
RestartSec=300
Restart=always

[Install]
WantedBy=multi-user.target
EOF
mkdir -p /etc/systemd/system/multi-user.target.wants
systemctl enable phonehome.service

cat <<'EOSH' >> /usr/local/sbin/sethost

##### Phonehome
PORTRANGE="5"
[ "$HOSTID" = "7a6741" ] && { PORTRANGE="6"; }
[ "$HOSTID" = "7c7ba8" ] && { PORTRANGE="7"; }
[ "$HOSTID" = "7ccb04" ] && { PORTRANGE="8"; }
[ "$HOSTID" = "7cb5e1" ] && { PORTRANGE="9"; }
[ "$HOSTID" = "7ca4de" ] && { PORTRANGE="0"; }

mkdir -p /run/phonehome
cp /etc/phonehome/* /run/phonehome
[ -f /run/phonehome/config ] || {
    cat <<EOF > /run/phonehome/config
Host phonehome
    User phonehome
    HostName tutor-web.net
    LocalForward 9025 localhost:25
    RemoteForward 9${PORTRANGE}22 localhost:22
    RemoteForward 9${PORTRANGE}80 localhost:80
EOF
}
chown nobody:nogroup /run/phonehome/*
chmod 600 /run/phonehome/*

EOSH
