#!/bin/sh
# Run in ~chroot env on image creation
set -eu

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
ln -frs /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

cat <<EOF > /etc/nginx/conf.d/proxy_cache.conf
proxy_cache off;
proxy_cache_path /var/local/nginx-proxy keys_zone=one:10M;

client_body_buffer_size 1M;
client_body_temp_path /var/local/nginx-client;
EOF

cat <<EOF > /srv/eias.lan/www/style.css
h1 {
    text-align: center;
}
h1 img {
    max-width: 80%;
}

div.links {
    margin: 0;
    margin-right: 30px;
    padding: 0;
    text-align: center;
}
div.links > a {
    display: inline-block;
    padding: 3em 1em;
    min-width: 10em;
    list-style-type: none;
    text-align: center;
    border: 1px solid #333;
    border-radius: 10px;
    margin: 10px;
}
div.links > a:hover,
div.links > a:active {
    background: #EEE;
}
EOF

mkdir -p /srv/eias.lan/www
cat <<EOF > /srv/eias.lan/www/index.html
<html>
<head>
  <title>Education in a Suitcase</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/style.css">
</head>
<body>
<h1><a href="/"><img src="/eias_logo.png" alt="Education in a Suitcase" /></a></h1>
<hr/>
EOF


mkdir -p /srv/eias.lan/www/status
cat <<EOF > /srv/eias.lan/www/status/index.html
<html>
<head>
  <title>Education in a Suitcase</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/style.css">
</head>
<body>
<h1><a href="/"><img src="/eias_logo.png" alt="Education in a Suitcase" /></a></h1>
<hr/>
<div class="links">
  <a href="/scripts/system-report">Generate system report</a>
</div>
EOF

mkdir -p /srv/eias.lan/scripts
cat <<'EOSH' > /srv/eias.lan/scripts/system-report
#!/bin/sh
TERM=dumb

echo "Content-type: text/plain;charset=utf-8"
echo "Cache-Control: no-store, no-cache, must-revalidate, max-age=0"
echo ""
echo ""

echo "***** Disk status *************************************************************"
df -h
echo ""
mount
echo ""
lsusb
echo "*******************************************************************************\n"

echo "***** Networking status *******************************************************"
ip addr
echo ""
ip route
#echo ""
#mtr --report-wide --report-cycles=3 8.8.8.8
echo ""
cat /run/dnsmasq.leases
echo "*******************************************************************************\n"

echo "***** Full process list *******************************************************"
systemctl --no-pager
echo "*******************************************************************************\n"

echo "***** System log **************************************************************"
/bin/journalctl --system --no-pager
echo "*******************************************************************************\n"

echo "***** Important Processes *****************************************************"
for p in phonehome smly tutor-web mysql kiwix kolibri nginx; do
    systemctl status -l $p
done
echo "*******************************************************************************\n"
EOSH
