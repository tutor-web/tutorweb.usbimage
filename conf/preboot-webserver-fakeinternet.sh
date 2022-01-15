#!/bin/sh
# Run in ~chroot env on image creation
set -eu

cat <<'EOF' > /etc/dnsmasq.d/fakeinternet
address=/captive.apple.com/172.16.16.1
address=/connectivitycheck.gstatic.com/172.16.16.1
address=/clients3.google.com/172.16.16.1
address=/detectportal.firefox.com/172.16.16.1
EOF

mkdir -p /etc/nginx/sites-available ; cat <<'EOF' > /etc/nginx/sites-available/fakeinternet
server {
  listen [::]:80;
  listen      80;
  listen [::]:443 ssl;
  listen      443 ssl;
  server_name captive.apple.com;
  server_name connectivitycheck.gstatic.com;
  server_name clients3.google.com;
  server_name detectportal.firefox.com;

  ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
  ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;

  root /srv/eias.lan/www;

  location /success.txt {  # http://detectportal.firefox.com/success.txt
    add_header Content-Type text/plain;
    return 200 'success';
  }

  location /hotspot-detect.html {
    add_header Content-Type text/html;
    return 200 '<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>';
  }

  location /canonical.html {
    add_header Content-Type text/html;
    return 200 '<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>';
  }

  location /generate_204 {
    return 204;
  }

  location /gen_204 {
    return 204;
  }
}
EOF
mkdir -p /etc/nginx/sites-enabled ; ln -rs /etc/nginx/sites-available/fakeinternet /etc/nginx/sites-enabled/fakeinternet
