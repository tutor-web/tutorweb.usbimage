#!/bin/sh -eu
# Run in ~chroot env on image creation

cat <<'EOF' > /etc/network/interfaces.d/local
auto br0
iface br0 inet static
    address 172.16.16.1
    netmask 255.255.255.0
    bridge_ports int0
    bridge_maxwait 5
    up /sbin/iptables-restore < /etc/network/iptables.up.rules

allow-hotplug wwan0
iface wwan0 inet dhcp

allow-hotplug wwan1
iface wwan1 inet dhcp

allow-hotplug wwan2
iface wwan2 inet dhcp

allow-hotplug other0
iface other0 inet dhcp

allow-hotplug int1
iface int1 inet manual
    pre-up ifconfig ${IFACE} 0.0.0.0 up
    post-up brctl addif br0 ${IFACE}
    pre-down brctl delif br0 ${IFACE}
    post-down ifconfig ${IFACE} down

allow-hotplug int2
iface int2 inet manual
    pre-up ifconfig ${IFACE} 0.0.0.0 up
    post-up brctl addif br0 ${IFACE}
    pre-down brctl delif br0 ${IFACE}
    post-down ifconfig ${IFACE} down

allow-hotplug int3
iface int3 inet manual
    pre-up ifconfig ${IFACE} 0.0.0.0 up
    post-up brctl addif br0 ${IFACE}
    pre-down brctl delif br0 ${IFACE}
    post-down ifconfig ${IFACE} down

allow-hotplug int4
iface int4 inet manual
    pre-up ifconfig ${IFACE} 0.0.0.0 up
    post-up brctl addif br0 ${IFACE}
    pre-down brctl delif br0 ${IFACE}
    post-down ifconfig ${IFACE} down
EOF

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
-A FORWARD -i br0 -j ACCEPT
-A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -p tcp -m tcp --dport ssh -j ACCEPT
-A FORWARD -j LOG
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
address=/modem.eias.lan/192.168.8.1

address=/captive.apple.com/172.16.16.1
address=/connectivitycheck.gstatic.com/172.16.16.1
address=/clients3.google.com/172.16.16.1
address=/detectportal.firefox.com/172.16.16.1

conf-dir=/var/local/etc/dnsmasq.d
EOF

mkdir -p /etc/hostapd ; cat <<'EOF' > /etc/hostapd/hostapd.conf
ssid=tutorweb-box
wpa_passphrase=tutorweb-box
hw_mode=g
channel=6

ap_max_inactivity=60
interface=wlan0
bridge=br0
logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
beacon_int=100
dtim_period=2
max_num_sta=255
rts_threshold=2347
fragm_threshold=2346
macaddr_acl=0
auth_algs=3
ignore_broadcast_ssid=0
wmm_enabled=1
wmm_ac_bk_cwmin=4
wmm_ac_bk_cwmax=10
wmm_ac_bk_aifs=7
wmm_ac_bk_txop_limit=0
wmm_ac_bk_acm=0
wmm_ac_be_aifs=3
wmm_ac_be_cwmin=4
wmm_ac_be_cwmax=10
wmm_ac_be_txop_limit=0
wmm_ac_be_acm=0
wmm_ac_vi_aifs=2
wmm_ac_vi_cwmin=3
wmm_ac_vi_cwmax=4
wmm_ac_vi_txop_limit=94
wmm_ac_vi_acm=0
wmm_ac_vo_aifs=2
wmm_ac_vo_cwmin=2
wmm_ac_vo_cwmax=3
wmm_ac_vo_txop_limit=47
wmm_ac_vo_acm=0
eapol_key_index_workaround=0
eap_server=0
own_ip_addr=127.0.0.1
wpa=1
wpa_pairwise=TKIP CCMP
EOF

cat <<'EOF' > /etc/sysctl.d/local-ipforward.conf
net.ipv4.conf.default.forwarding=1
net.ipv4.conf.all.forwarding=0
net.ipv4.ip_forward=1
EOF

cat <<'EOF' > /etc/udev/rules.d/70-persistent-net.rules
# Bridge and loopback get left alone
SUBSYSTEM=="net", KERNEL=="br*", GOTO="persistent_net_end"
SUBSYSTEM=="net", KERNEL=="lo", GOTO="persistent_net_end"

# Internal network port (e1000e - NUC, e1000 - QEMU)
SUBSYSTEM=="net", DRIVERS=="e1000e", NAME="int0", GOTO="persistent_net_end"
SUBSYSTEM=="net", DRIVERS=="e1000",  NAME="int0", GOTO="persistent_net_end"

# Internal wifi card
SUBSYSTEM=="net", DRIVERS=="iwlwifi", NAME="wlan0", GOTO="persistent_net_end"

# USB modem used for extra access point
SUBSYSTEM=="net", DRIVERS=="usb", ATTR{address}=="1a:ff:0f:fe:10:22", \
    NAME="int1", GOTO="persistent_net_end"

# USB devices are consided external access
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="usb", NAME="wwan%n", GOTO="persistent_net_end"

# Anything else is unknown
SUBSYSTEM=="net", ACTION=="add", NAME="other%n", GOTO="persistent_net_end"
LABEL="persistent_net_end"
EOF

cat <<'EOF' > /etc/udev/rules.d/75-persistent-net-generator.rules
# Disable persistent name generator
EOF

cat <<'EOF' > /etc/udev/rules.d/modem-modeswitch.rules
SUBSYSTEMS=="scsi", \
    ATTRS{model}=="Mass Storage    ", \
    ATTRS{vendor}=="HUAWEI  ", \
    RUN += "/usr/sbin/usb_modeswitch -v12d1 -p1f01 -M55534243123456780000000000000a11062000000000000100000000000000"
EOF

apt-get install -y net-tools ifupdown bridge-utils dnsmasq hostapd iw ssh usb-modeswitch iptables iputils-ping isc-dhcp-client rsync

cat <<'EOF' > /etc/default/hostapd
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF


cat <<'EOSH' >> /usr/local/sbin/sethost

##### DNSMasq
mkdir -p /var/local/etc/dnsmasq.d
cat <<EOF > /var/local/etc/dnsmasq.d/hosts
cname=twbox-${HOSTID},eias.lan
cname=twbox-${HOSTID}.tutor-web.net,eias.lan
EOF

EOSH
