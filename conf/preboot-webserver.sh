#!/bin/sh -eu
# Run in ~chroot env on image creation

apt-get install -y nginx fcgiwrap

usermod -aG systemd-journal www-data

awk '
/(access|error)_log/ { print "\t" $1 " syslog:server=unix:/dev/log;";next }
/server_names_hash_bucket_size 64;/ { print "\tserver_names_hash_bucket_size 128;"; next }
{print}' \
   /etc/nginx/nginx.conf > /etc/nginx/nginx.conf.n
mv /etc/nginx/nginx.conf.n /etc/nginx/nginx.conf

cat <<'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /srv/eias.lan/www;

    location /scripts/ {
        gzip off;
        root  /srv/eias.lan/scripts;

        fastcgi_pass  unix:/var/run/fcgiwrap.socket;
        include /etc/nginx/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME  /srv/eias.lan/$fastcgi_script_name;
    }

    location /shell/ {
        return 301 http://shell.eias.lan;
    }
}
EOF
ln -rs /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

cat <<EOF > /etc/nginx/conf.d/proxy_cache.conf
proxy_cache off;
proxy_cache_path /var/local/nginx-proxy keys_zone=one:10M;

client_body_buffer_size 1M;
client_body_temp_path /var/local/nginx-client;
EOF
