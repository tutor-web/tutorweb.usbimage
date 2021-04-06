apt-get install -y usb-modeswitch

cat <<'EOF' > /etc/udev/rules.d/modem-modeswitch.rules
SUBSYSTEMS=="scsi", \
    ATTRS{model}=="Mass Storage    ", \
    ATTRS{vendor}=="HUAWEI  ", \
    RUN += "/usr/sbin/usb_modeswitch -v12d1 -p1f01 -M55534243123456780000000000000a11062000000000000100000000000000"
EOF

mkdir -p /etc/dnsmasq.d ; cat <<'EOF' > /etc/dnsmasq.d/usbmodem-config
address=/modem.eias.lan/192.168.8.1
EOF

cat <<EOF >> /srv/eias.lan/www/status/index.html
<div class="links">
  <a href="http://modem.eias.lan">Modem web interface</a>
</div>
EOF
