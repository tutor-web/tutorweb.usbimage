#!/bin/sh
# Run in ~chroot env on image creation
set -eu

cat <<'EOF' > /etc/apt/apt.conf.d/no-recommends
APT { Install-Recommends "false"; };
EOF

cat <<'EOF' | debconf-set-selections -v
locales locales/locales_to_be_generated	multiselect	en_GB.UTF-8 UTF-8
locales locales/default_environment_locale	select	en_GB.UTF-8

tzdata  tzdata/Zones/Australia  select
tzdata  tzdata/Zones/US         select
tzdata  tzdata/Zones/Asia       select
tzdata  tzdata/Zones/Etc        select  UTC
tzdata  tzdata/Zones/SystemV    select
tzdata  tzdata/Zones/Arctic     select
tzdata  tzdata/Zones/Pacific    select
tzdata  tzdata/Zones/Antarctica select
tzdata  tzdata/Zones/Europe     select
tzdata  tzdata/Zones/Africa     select
tzdata  tzdata/Zones/America    select
tzdata  tzdata/Areas            select
tzdata  tzdata/Zones/Atlantic   select
tzdata  tzdata/Zones/Indian     select

nullmailer nullmailer/defaultdomain     text	box.tutor-web.net
nullmailer nullmailer/relayhost         text	localhost smtp --port=9025
nullmailer shared/mailname              text	twbox.tutor-web.net
nullmailer nullmailer/adminaddr         text	admin@tutor-web.net
EOF

cat <<'EOF' > /etc/apt/apt.conf.d/99no-pdiffs
Acquire::PDiffs "0";
EOF

sed -i 's/errors=remount-ro/ro,errors=remount-ro/' /etc/fstab
cat <<'EOF' >> /etc/fstab
none		/tmp		tmpfs	nodev,nosuid					0 0
EOF

cat <<'EOF' >> /etc/hosts
127.0.0.22	smtp-relay
172.16.16.1	eias.lan box.smileyco.in
EOF

cat <<'EOF' > /etc/systemd/journald.conf
[Journal]
Storage=volatile
EOF

cat <<'EOF' > /etc/systemd/logind.conf
[Login]
HandlePowerKey=poweroff
EOF

sed -i 's/main$/main contrib non-free/' /etc/apt/sources.list
cat <<'EOF' > /etc/apt/sources.list.d/backports.list
deb http://deb.debian.org/debian buster-backports main
EOF
apt-get update

# Unneeded things from image
apt-get purge -y rsyslog

# admin
apt-get install -y sudo locales dialog nullmailer apt-utils cron logrotate elinks links2

# firmware
apt-get install -y firmware-linux

# system
apt-get install -y dbus

# util
apt-get install -y nano vim ne less screen usbutils curl wget ssl-cert strace netcat-traditional e2fsprogs

mkdir /twdata

cat <<'EOSH' > /usr/local/sbin/twmounts
#!/bin/sh -e
# Mount /twdata, or if it's not there then use a tmpfs
mountpoint -q /twdata || for f in `seq 1 30`; do
    mount /dev/disk/by-label/twdata /twdata && break
    sleep 1
done
mountpoint -q /twdata || mount -t tmpfs tmpfs /twdata

# Overlay FS for /var
mkdir -p /twdata/var_work ; mkdir -p /twdata/var
mount -t overlay -o lowerdir=/var,upperdir=/twdata/var,workdir=/twdata/var_work \
    overlay /var
EOSH
chmod +x /usr/local/sbin/twmounts

cat <<'EOF' > /etc/systemd/system/twmounts.service
[Unit]
Description=Mount TW FS overlays
DefaultDependencies=no
Before=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/twmounts
StandardOutput=syslog+console
StandardError=syslog+console

[Install]
WantedBy=local-fs.target
EOF
mkdir -p /etc/systemd/system/basic.target.wants
systemctl enable twmounts
