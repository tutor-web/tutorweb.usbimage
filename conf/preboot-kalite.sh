#!/bin/sh
# Run in ~chroot env on image creation
set -eu

useradd --system kalite

cat <<'EOF' | debconf-set-selections -v
ka-lite-bundle  ka-lite/user    string kalite
EOF

# TODO: Cache this outside of VM
mkdir /staging/
wget -O /staging/kalite-bundle.deb https://learningequality.org/r/deb-bundle-installer-0-17

apt-get install python-pkg-resources
dpkg -i /staging/kalite-bundle.deb

mkdir -p /var/kalite/.kalite
chown kalite:kalite  /var/kalite/.kalite
echo "/var/kalite/.kalite" > /etc/ka-lite/home

mkdir -p /etc/nginx/sites-available ; cat <<'EOF' > /etc/nginx/sites-available/kalite
upstream kalite {
  server 127.0.0.1:8008;
}

server {
  listen [::]:80;
  listen      80;
  server_name ka.eias.lan;

  location / {
    proxy_pass http://kalite;
    proxy_cache off;
  }
}
EOF
mkdir -p /etc/nginx/sites-enabled ; ln -rs /etc/nginx/sites-available/kalite /etc/nginx/sites-enabled/kalite
