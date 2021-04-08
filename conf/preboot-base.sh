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

# Remove pre-baked machine ID
echo "" > /etc/machine-id

cat <<'EOF' > /etc/systemd/journald.conf
[Journal]
Storage=volatile
EOF

cat <<'EOF' > /etc/systemd/logind.conf
[Login]
HandlePowerKey=poweroff
EOF

cat <<'EOF' > /etc/sysctl.d/quiet-kernel.conf
kernel.printk = 2 4 1 7
EOF

cat <<'EOF' > /etc/sysctl.d/frequent-writes.conf
# Write back data every 5s
vm.dirty_expire_centisecs = 500
EOF

sed -i 's/main$/main contrib non-free/' /etc/apt/sources.list
cat <<'EOF' > /etc/apt/sources.list.d/backports.list
deb http://deb.debian.org/debian buster-backports main
EOF
apt-get update

# Unneeded things from image
apt-get purge -y rsyslog

# admin
apt-get install -y sudo locales dialog nullmailer apt-utils cron logrotate beep

# firmware
apt-get install -y firmware-linux

# system
apt-get install -y dbus

# util
apt-get install -y nano vim ne less screen usbutils curl wget ssl-cert strace netcat-traditional e2fsprogs xterm elinks

mkdir /twdata
mkdir /twextra

ln -fs /var/local/hostname /etc/hostname
ln -fs /var/local/mailname /etc/mailname

cat <<'EOSH' > /usr/local/sbin/twmounts
#!/bin/sh
# Load pcspkr early, so we can beep: https://pages.mtu.edu/~suits/notefreqs.html
modprobe pcspkr || true

# Mount /twdata, or if it's not there then use a tmpfs
mountpoint -q /twdata || for f in `seq 1 10`; do
    beep -f 523.25 -l 50  # C5
    [ -e /dev/disk/by-label/twdata ] && fsck -y /dev/disk/by-label/twdata
    [ -e /dev/disk/by-label/twdata ] && mount /dev/disk/by-label/twdata /twdata && break
    sleep 1
done
mountpoint -q /twdata || {
    beep -f 261.63 -l 50  # C4
    mount -t tmpfs tmpfs /twdata
}
beep -f 1046.50 -l 50  # C6

# Mount /twextra, if there is one
[ -e /dev/disk/by-label/twextra ] && mount -o ro /dev/disk/by-label/twextra /twextra

# Overlay FS for /var
mkdir -p /twdata/var_work ; mkdir -p /twdata/var
mount -t overlay -o lowerdir=/var,upperdir=/twdata/var,workdir=/twdata/var_work \
    overlay /var
beep -f 2093.00 -l 50  # C7

[ -f "/var/local/hostname" ] || echo "twbox-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8)" > /var/local/hostname
/bin/hostname $(cat /var/local/hostname)
echo "$(cat /var/local/hostname).tutor-web.net" > /var/local/mailname
mkdir -p /var/run/dnsmasq.d/
cat <<EOF > /var/run/dnsmasq.d/localnames
cname=$(hostname),eias.lan
cname=$(hostname).tutor-web.net,eias.lan
EOF
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

# Add any users in preload
cat /twpreload/twadmins | while IFS=: read -r USER PWD; do
    echo "=== $USER"
    adduser --disabled-password --gecos "" $USER
    usermod -a -G sudo $USER
done
cat /twpreload/twadmins | chpasswd
rm /twpreload/twadmins

cat <<'EOSH' > /usr/local/sbin/twleds
#!/bin/sh
# Configure LEDs if possible
set -eu

[ -d '/sys/class/leds/apu2:green:2' ] && echo "disk-activity" > '/sys/class/leds/apu2:green:2/trigger'
[ -d '/sys/class/leds/apu2:green:3' ] && echo "phy0rx" > '/sys/class/leds/apu2:green:3/trigger'
exit 0
EOSH
chmod a+x /usr/local/sbin/twleds

cat <<'EOF' > /etc/systemd/system/twleds.service
[Unit]
Description=Configure APU2 LEDs
# NB: i.e. so phy0rx is available as a trigger
After=nss-lookup.target
Wants=nss-lookup.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/twleds

[Install]
WantedBy=multi-user.target
EOF
mkdir -p /etc/systemd/system/basic.target.wants
systemctl enable twleds
