#!/bin/sh
# Run in ~chroot env on image creation
set -eu

# Remote configuration:
# adduser --disabled-password --home /home/phonehome --shell /bin/true --ingroup nogroup phonehome
# Add key to /home/phonehome/.ssh/authorized_keys
# cat <<EOF >> /etc/ssh/sshd_config
# Match User phonehome
#     ChrootDirectory /home/phonehome
#     StreamLocalBindUnlink yes
#     StreamLocalBindMask 0111
# EOF
# cat <<EOF > /home/phonehome/true.c
# /* gcc true.c -static -o ./bin/true */
# int main () { return 0; }
# gcc /home/phonehome/true.c -static -o /home/phonehome/bin/true

# Connecting from remote:
# ssh -o "ProxyCommand socat - UNIX-CLIENT:/home/phonehome/tmp/(host)-ssh" tutor@localhost

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
After=sethost.service

[Service]
User=nobody
Type=simple
ExecStart=/bin/sh -c 'exec /usr/bin/ssh -NTC \
    -o ServerAliveInterval=60 \
    -o ExitOnForwardFailure=yes \
    -o UserKnownHostsFile=/etc/phonehome/known_hosts \
    -i /twpreload/phonehome/id_rsa \
    -L 9025:localhost:25 \
    -R /tmp/$$(hostname)-ssh:localhost:22 \
    -R /tmp/$$(hostname)-http:localhost:80 \
    -F /twpreload/phonehome/config \
    phonehome'

# Restart every >2 seconds to avoid StartLimitInterval failure
RestartSec=300
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable phonehome.service
