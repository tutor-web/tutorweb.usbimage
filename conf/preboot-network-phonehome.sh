#!/bin/sh -eu
# Run in ~chroot env on image creation

cat <<'EOSH' >> /usr/local/sbin/phonehome-setup
#!/bin/sh -eu

PORTRANGE="5"
HOSTNAME="$(hostname)"
[ "$HOSTNAME" = "twbox-7a6741" ] && { PORTRANGE="6"; }
[ "$HOSTNAME" = "twbox-7c7ba8" ] && { PORTRANGE="7"; }
[ "$HOSTNAME" = "twbox-7ccb04" ] && { PORTRANGE="8"; }
[ "$HOSTNAME" = "twbox-7cb5e1" ] && { PORTRANGE="9"; }
[ "$HOSTNAME" = "twbox-7ca4de" ] && { PORTRANGE="0"; }

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
chmod +x /usr/local/sbin/phonehome-setup

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
ExecStartPre=/usr/local/sbin/phonehome-setup

# Restart every >2 seconds to avoid StartLimitInterval failure
RestartSec=300
Restart=always

[Install]
WantedBy=multi-user.target
EOF
mkdir -p /etc/systemd/system/multi-user.target.wants
systemctl enable phonehome.service
