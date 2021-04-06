#!/bin/sh
# Run in ~chroot env on image creation
set -eu

cat <<'EOF' > /etc/network/interfaces.d/local
iface br0 inet static
    address 172.16.16.1
    netmask 255.255.255.0
    bridge_ports none
    bridge_maxwait 5
    up /sbin/iptables-legacy-restore < /etc/network/iptables.up.rules

iface net-bridge inet manual
    pre-up ifup br0
    pre-up ifconfig ${IFACE} 0.0.0.0 up
    post-up brctl addif br0 ${IFACE}
    pre-down brctl delif br0 ${IFACE}
    post-down ifconfig ${IFACE} down

iface net-wwan inet dhcp

allow-hotplug /*
mapping *
    script /etc/network/mapping.sh
EOF

cat <<'EOF' > /etc/network/mapping.sh
case $1 in
    wwan*)
        echo "net-wwan"
        ;;
    ens*|enp*|eth*)
        echo "net-bridge"
        ;;
    wlp*)
        # NB: See preboot-network-wifiap.sh
        echo "net-wifiap"
        ;;
    *)
        echo "$1"
        ;;
esac
EOF
chmod a+x /etc/network/mapping.sh

echo "br_netfilter" >> /etc/modules

cat <<'EOF' > /etc/network/iptables.up.rules
*filter

:ssh - [0:0]
-A ssh -m recent --name SSH --set
-A ssh -m recent --name SSH --update --seconds 60 --hitcount 10 -m limit -j REJECT --reject-with icmp-admin-prohibited
-A ssh -m recent --name SSH --update --seconds 60 --hitcount 10 -j DROP
-A ssh -j ACCEPT

:INPUT DROP [0:0]
-A INPUT -p ipv6 -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -s 127.0.0.0/8 ! -i lo -j LOG
-A INPUT -s 127.0.0.0/8 ! -i lo -j DROP
-A INPUT -i br0 -j ACCEPT
-A INPUT -s 172.16.16.0/24 ! -i br0 -j LOG
-A INPUT -s 172.16.16.0/24 ! -i br0 -j DROP
-A INPUT -d 255.255.255.255/32 -j ACCEPT
-A INPUT -d 224.0.0.0/4 -j ACCEPT

-A INPUT -p icmp -j ACCEPT
-A INPUT -p tcp -m tcp ! --syn -j ACCEPT
-A INPUT -p tcp -m tcp --dport ssh -j ssh
-A INPUT -p tcp -m tcp --dport 6666 -j ACCEPT
-A INPUT -p tcp -m tcp --dport auth -j REJECT --reject-with tcp-reset
-A INPUT -p tcp -m tcp --dport ftp -j DROP
-A INPUT -p tcp -m tcp --dport smtp -j DROP
-A INPUT -p tcp -m tcp --dport telnet -j DROP
-A INPUT -p tcp -m tcp --dport 135:139 -j DROP
-A INPUT -p tcp -m tcp --dport 445 -j DROP
-A INPUT -p udp -m udp --dport ntp -j ACCEPT
-A INPUT -p udp -m udp --dport 1024:65535 -j ACCEPT
-A INPUT -j LOG
-A INPUT -j DROP

:FORWARD DROP [0:0]
-A INPUT -i lo -j ACCEPT
-A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i br0 -p tcp -m tcp --dport ssh -j ACCEPT
-A FORWARD -i br0 -p tcp -m tcp --dport domain -j ACCEPT
-A FORWARD -i br0 -p udp -m udp --dport domain -j ACCEPT
EOF

cat /twpreload/twhosts | while read -r HOST; do
    echo "# ${HOST}" >> /etc/network/iptables.up.rules
    echo "-A FORWARD -i br0 -d $(getent ahostsv4 ${HOST} | cut -d' ' -f1 | head -1) -j ACCEPT" >> /etc/network/iptables.up.rules
done

cat <<'EOF' >> /etc/network/iptables.up.rules
-A FORWARD -i br0 -j REJECT
-A FORWARD -j DROP

:OUTPUT ACCEPT [0:0]

COMMIT

*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

COMMIT

*nat
:PREROUTING ACCEPT [0:0]
#-A PREROUTING -p tcp --dport 2201 -j DNAT --to 192.168.192.10:22
# -A PREROUTING -p tcp -m multiport --dports 20000:21000 -j DNAT --to 10.150.1.2

:OUTPUT ACCEPT [0:0]

:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o lo -j ACCEPT
-A POSTROUTING -o br0 -j ACCEPT
-A POSTROUTING -s 172.16.16.0/24 -j MASQUERADE

COMMIT
EOF

mkdir -p /etc/dnsmasq.d ; cat <<'EOF' > /etc/dnsmasq.d/local-config
interface=br0
dhcp-range=172.16.16.10,172.16.16.255,1h
domain=eias.lan

expand-hosts
domain-needed
bogus-priv

resolv-file=/tmp/resolv.upstream.conf
dhcp-leasefile=/run/dnsmasq.leases

address=/.eias.lan/172.16.16.1

conf-dir=/var/run/dnsmasq.d
EOF

cat <<'EOF' > /etc/sysctl.d/local-ipforward.conf
net.ipv4.conf.default.forwarding=1
net.ipv4.conf.all.forwarding=0
net.ipv4.ip_forward=1
EOF

cat <<'EOF' > /etc/udev/rules.d/70-persistent-net.rules
# USB devices are consided external access
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="usb", NAME="wwan%k", GOTO="persistent_net_end"

# virtio devices are external, for development
SUBSYSTEM=="net", ACTION=="add", SUBSYSTEMS=="virtio", NAME="wwan%k", GOTO="persistent_net_end"

# An APU's 3rd port is WWAN
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="igb", KERNEL=="enp3s0", NAME="wwan%k", GOTO="persistent_net_end"

LABEL="persistent_net_end"
EOF

cat <<'EOF' > /etc/udev/rules.d/75-persistent-net-generator.rules
# Disable persistent name generator
EOF

apt-get install -y net-tools ifupdown bridge-utils dnsmasq resolvconf iw ssh iptables iputils-ping isc-dhcp-client rsync

ln -fs /run/hostname /etc/hostname
ln -fs /run/mailname /etc/mailname

cat <<'EOSH' > /usr/local/sbin/sethost
#!/bin/sh

##### Hostname
ADDR_FILE="$(ls -1t /sys/class/net/en*/address | head -1)"
HOSTID="000000"
[ -f "${ADDR_FILE}" ] && HOSTID="$(/bin/sed 's/://g ; s/^.\{6\}//' "${ADDR_FILE}")"
/bin/hostname twbox-$HOSTID
hostnamectl set-hostname twbox-$HOSTID
/bin/hostname > /run/hostname
echo "twbox-${HOSTID}.tutor-web.net" > /run/mailname

##### DNSMasq
mkdir -p /var/run/dnsmasq.d/
cat <<EOF > /var/run/dnsmasq.d/localnames
cname=twbox-${HOSTID},eias.lan
cname=twbox-${HOSTID}.tutor-web.net,eias.lan
EOF

beep -f 2217.46 -l 50 # C#7
EOSH
chmod a+x /usr/local/sbin/sethost

cat <<'EOF' > /etc/systemd/system/sethost.service
[Unit]
Description=Configure hostname from MAC
DefaultDependencies=no
After=networking.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/sethost

[Install]
WantedBy=network.target
RequiredBy=dnsmasq.service
EOF
systemctl enable sethost.service
