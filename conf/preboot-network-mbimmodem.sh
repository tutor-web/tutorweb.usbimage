apt-get install -y libmbim-utils

# Populate config
echo "" > /var/local/mbim-network.conf
[ -e /twpreload/mbim-network.conf ] && mv /twpreload/mbim-network.conf /var/local/mbim-network.conf
chown www-data /var/local/mbim-network.conf
ln -rsf /var/local/mbim-network.conf /etc/mbim-network.conf

cat <<'EOSH' > /usr/local/sbin/mbim
#!/bin/sh

WDM_DEVICE="/dev/$2"
while [ -z "${NET_DEVICE}" ]; do
    sleep 1
    NET_DEVICE="$(ls -1 /sys/class/*/$(basename ${WDM_DEVICE})/device/net/ 2>/dev/null)"
done

if [ "$1" = "start" ]; then
    mbimcli -d $WDM_DEVICE --set-radio-state=on
    mbim-network $WDM_DEVICE start
    mbim-network $WDM_DEVICE status || true
    ifdown ${NET_DEVICE} || true
    ifup ${NET_DEVICE}
elif [ "$1" = "stop" ]; then
    ifdown ${NET_DEVICE}
    mbim-network $WDM_DEVICE stop
    mbimcli -d $WDM_DEVICE --set-radio-state=off
else
    echo "Usage: $0 (start|stop)"
fi
EOSH
chmod a+x /usr/local/sbin/mbim

cat <<'EOF' > /etc/systemd/system/mbim\@.service
[Unit]
Description=Connect via MBIM modem
After=networking.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/mbim start %i
ExecStop=/usr/local/sbin/mbim stop %i
TimeoutStartSec=120s
EOF

cat <<'EOF' > /etc/udev/rules.d/95-mbim.rules
ACTION=="add", \
    SUBSYSTEM=="usbmisc" \
    DRIVERS=="cdc_mbim" \
    TAG+="systemd", \
    ENV{SYSTEMD_WANTS}="mbim@%k.service"
EOF

cat <<'EOSH' > /srv/eias.lan/scripts/configure-mbim
#!/bin/sh
CONF_FILE="/var/local/mbim-network.conf"

if [ "${REQUEST_METHOD}" = "POST" ]; then
    awk 'BEGIN {RS="&"} /^[A-Z_]+=[a-zA-Z0-9_\-.]+$/ {print}' > ${CONF_FILE}
    cat <<EOF
Status: 302 Moved Temporarily
Location: /scripts/configure-mbim
URI: /scripts/configure-mbim
Connection: close
Content-type: text/plain; charset=utf-8

OK
EOF
else
    . "${CONF_FILE}"
    cat <<EOF
Content-type: text/html;charset=utf-8
Cache-Control: no-store, no-cache, must-revalidate, max-age=0


<html>
<head>
  <title>Education in a Suitcase</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <h1><a href="/status"><img src="/eias_logo.png" alt="Education in a Suitcase" /></a></h1>
  <hr/>
  <form action="/scripts/configure-mbim" method="POST" ><dl>
    <dt>APN</dt><dd><input type="text" name="APN" value="${APN}" /></dd>
    <dt>APN_USER</dt><dd><input type="text" name="APN_USER" value="${APN_USER}" /></dd>
    <dt>APN_PASS</dt><dd><input type="text" name="APN_PASS" value="${APN_PASS}" /></dd>
    <dt>APN_AUTH (<code>PAP</code>, <code>CHAP</code> or <code>MSCHAPV2</code>)</dt><dd><input name="APN_AUTH" value="${APN_AUTH}"/></dd>
    <dt>PROXY (<code>yes</code> or nothing)</dt><dd><input name="PROXY" value="${PROXY}"/></dd>
    <input type="submit" value="Save">
  </dl></form>
</body>
EOF
fi
EOSH
chmod a+x /srv/eias.lan/scripts/configure-mbim

cat <<EOF >> /srv/eias.lan/www/status/index.html
<div class="links">
  <a href="http://eias.lan/scripts/configure-mbim">Configure modem APN</a>
</div>
EOF
