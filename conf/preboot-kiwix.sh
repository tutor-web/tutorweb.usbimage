#!/bin/sh
# Run in ~chroot env on image creation
set -eu

apt-get install -y unzip
apt-get install -y -t buster-backports kiwix-tools


mkdir -p /etc/nginx/sites-available ; cat <<'EOF' > /etc/nginx/sites-available/kiwix
upstream kiwix {
  server 127.0.0.1:8280;
}

server {
  listen [::]:80;
  listen      80;
  server_name kiwix.eias.lan;

  location / {
    proxy_pass http://kiwix;
    proxy_cache off;
    # https://github.com/kiwix/kiwix-tools/issues/15
    proxy_set_header Accept-Encoding "";
  }
}
EOF
mkdir -p /etc/nginx/sites-enabled ; ln -rs /etc/nginx/sites-available/kiwix /etc/nginx/sites-enabled/kiwix


cat <<'EOSH' >> /usr/local/sbin/kiwix-setup
#!/bin/sh -eu

echo "" > /var/tmp/kiwix-library.xml
ls -1 \
    /twpreload/kiwix/*.zim \
    /twpreload/kiwix/*.zimaa \
    /twdata/kiwix/*.zim \
    /twdata/kiwix/*.zimaa \
    | xargs -L1 kiwix-manage /var/tmp/kiwix-library.xml add
EOSH
chmod +x /usr/local/sbin/kiwix-setup


cat <<'EOF' > /etc/systemd/system/kiwix.service
[Unit]
Description=Kiwix
After=network.target

[Service]
ExecStart=/usr/bin/kiwix-serve --port=8280 --library /var/tmp/kiwix-library.xml
ExecStartPre=/usr/local/sbin/kiwix-setup
DynamicUser=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl enable kiwix
