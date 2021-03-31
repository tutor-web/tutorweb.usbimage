#!/bin/sh
# Run in ~chroot env on image creation
set -eu

apt-get install -y shellinabox

cat <<'EOF' > /etc/default/shellinabox
# Should shellinaboxd start automatically
SHELLINABOX_DAEMON_START=1

# TCP port that shellinboxd's webserver listens on
SHELLINABOX_PORT=4200

# Parameters that are managed by the system and usually should not need
# changing:
# SHELLINABOX_DATADIR=/var/lib/shellinabox
# SHELLINABOX_USER=shellinabox
# SHELLINABOX_GROUP=shellinabox

# Any optional arguments (e.g. extra service definitions).  Make sure
# that that argument is quoted.
#
#   Beeps are disabled because of reports of the VLC plugin crashing
#   Firefox on Linux/x86_64.
SHELLINABOX_ARGS="--no-beep --localhost-only --disable-ssl"
EOF

mkdir -p /etc/nginx/sites-available ; cat <<'EOF' > /etc/nginx/sites-available/shell
upstream shell {
  server 127.0.0.1:8280;
}

server {
  listen [::]:80;
  listen      80;
  server_name shell.eias.lan;

  location / {
    proxy_pass http://shell;
    proxy_cache off;
  }
}
EOF
mkdir -p /etc/nginx/sites-enabled ; ln -rs /etc/nginx/sites-available/shell /etc/nginx/sites-enabled/shell

cat <<'EOF' > /etc/dnsmasq.d/shell
cname=shell.eias.lan,eias.lan
EOF

cat <<EOF >> /srv/eias.lan/www/status/index.html
  <a href="http://shell.eias.lan">System shell</a>
EOF
