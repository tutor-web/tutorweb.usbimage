#!/bin/sh -eu
# Run in ~chroot env on image creation

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

cat <<'EOF' > /etc/systemd/system/sethost.service
[Unit]
Description=Setup host
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=basic.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/sethost
StandardOutput=syslog+console
StandardError=syslog+console

[Install]
WantedBy=basic.target
EOF
mkdir -p /etc/systemd/system/basic.target.wants
systemctl enable sethost

sed -i 's/main$/main contrib non-free/' /etc/apt/sources.list
cat <<'EOF' > /etc/apt/sources.list.d/backports.list
deb http://deb.debian.org/debian buster-backports main
EOF
apt-get update

# admin
apt-get install -y sudo locales dialog nullmailer apt-utils cron logrotate elinks links2 ntpdate

# firmware
apt-get install -y firmware-linux

# system
apt-get install -y dbus

# util
apt-get install -y nano vim ne less screen usbutils curl wget ssl-cert strace netcat-traditional e2fsprogs


cat <<'EOSH' >> /usr/local/sbin/sethost
#!/bin/sh -e
HOSTID="000000"
[ -f /sys/class/net/int0/address ] && HOSTID="$(/bin/sed 's/://g ; s/^.\{6\}//' /sys/class/net/int0/address)"

# Mount /var/local, or if it's not there then use a tmpfs
mountpoint -q /var/local || for f in `seq 1 30`; do
    mount /dev/disk/by-label/twdata /var/local && break
    sleep 1
done
mountpoint -q /var/local || mount -t tmpfs tmpfs /var/local

mkdir -p /var/local/etc
/bin/hostname twbox-$HOSTID
/bin/hostname > /var/local/etc/hostname
echo "twbox-${HOSTID}.tutor-web.net" > /var/local/etc/mailname

##### Systemd bodges
for dir in \
        /var/lib/systemd \
        /var/lib/container \
        /var/lib/dhcp \
        /var/cache \
        /var/log \
    ; do
    mkdir -p /var/local${dir}
done

##### nullmailer
mount -t tmpfs tmpfs /var/spool/nullmailer
mkdir -p /var/spool/nullmailer/queue
mkdir -p /var/spool/nullmailer/tmp
mkfifo /var/spool/nullmailer/trigger
chown mail:root /var/spool/nullmailer/*

EOSH
chmod +x /usr/local/sbin/sethost
