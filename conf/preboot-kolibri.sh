#!/bin/sh
# Run in ~chroot env on image creation
set -eu

cat <<'EOF' | debconf-set-selections -v
kolibri kolibri/init boolean true
kolibri kolibri/user string kolibri
EOF

apt-get install -y dirmngr gnupg
echo "deb http://ppa.launchpad.net/learningequality/kolibri/ubuntu cosmic main" \
    > /etc/apt/sources.list.d/learningequality-ubuntu-kolibri-cosmic.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys DC5BAA93F9E4AE4F0411F97C74F88ADB3194DD81
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y kolibri python3-cryptography

echo 'KOLIBRI_LISTEN_PORT="8208"' >> /etc/kolibri/daemon.conf
chown -R kolibri:kolibri /var/kolibri

mkdir -p /etc/nginx/sites-available ; cat <<'EOF' > /etc/nginx/sites-available/kolibri
upstream kolibri {
  server 127.0.0.1:8208;
}

server {
  listen [::]:80;
  listen      80;
  server_name kolibri.eias.lan;

  location / {
    proxy_pass http://kolibri;
    proxy_cache off;
  }
}
EOF
mkdir -p /etc/nginx/sites-enabled ; ln -rs /etc/nginx/sites-available/kolibri /etc/nginx/sites-enabled/kolibri

cat <<EOF >> /srv/eias.lan/www/index.html
<div class="links">
  <a href="http://kolibri.eias.lan">Kolibri (Khan academy)</a>
</div>
EOF
