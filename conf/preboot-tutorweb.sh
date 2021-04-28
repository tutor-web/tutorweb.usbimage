#!/bin/sh
# Run in ~chroot env on image creation
set -eu

MYSQLROOTPASS="$(xxd -ps -l 22 /dev/urandom)"
MYSQLTUTPASS="$(xxd -ps -l 22 /dev/urandom)"
TWPASS="$(xxd -ps -l 22 /dev/urandom)"
[ -f '/var/local/smly/smileycoin.conf' ] && RPCPASS="$(awk -F= '/rpcpassword\=/ { print $2; }' /var/local/smly/smileycoin.conf)" || RPCPASS="none"
[ -f '/var/local/smly/smileycoin.conf' ] && WALLETPASS="$(xxd -ps -l 22 /dev/urandom)" || WALLETPASS="none"

######### Install MySQL

cat <<EOF | debconf-set-selections -v
mysql-server mysql-server/root_password password "${MYSQLROOTPASS}"
mysql-server mysql-server/root_password_again password "${MYSQLROOTPASS}"
EOF

cat <<EOF > /root/.my.cnf
[client]
user=root
password=${MYSQLROOTPASS}
EOF
chmod 400 /root/.my.cnf

apt-get install -y mariadb-server

cat <<'EOF' > /etc/mysql/conf.d/no-error-log.cnf
[mysqld]
general_log = 0
log_error = /tmp/mysql_error.log
EOF

# NB: Var interpolation on, for password
cat <<EOSH >> /usr/local/sbin/tutorwebdb
#!/bin/sh
set -eu

mountpoint -q /srv/tutorweb.buildout/var \
    || mount --bind /var/local/tutorweb /srv/tutorweb.buildout/var

mkdir -p /var/local/tutorweb/filestorage
chown tutorweb /var/local/tutorweb/filestorage
mkdir -p /var/local/tutorweb/blobstorage
chown tutorweb /var/local/tutorweb/blobstorage

if [ -f /var/lib/mysql/tw_quizdb/db.opt ]; then
    cat <<EOF | mysql -u root
ALTER USER 'tw_quizdb'@'localhost' IDENTIFIED BY '${MYSQLTUTPASS}';
EOF
else
    cat <<EOF | mysql -u root
CREATE DATABASE tw_quizdb;
CREATE USER 'tw_quizdb'@'localhost' IDENTIFIED BY '${MYSQLTUTPASS}';
GRANT ALL PRIVILEGES ON tw_quizdb. * TO 'tw_quizdb'@'localhost';
EOF
fi

# TODO: mysql_secure_installation ? 
# cat <<EOF | mysql -u root -p
# GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost'
# IDENTIFIED BY 'WsgJtZ8QfUd1oYRa';
# EOF

exit 0
EOSH
chmod 700 /usr/local/sbin/tutorwebdb

cat <<'EOF' > /etc/systemd/system/tutorwebdb.service
[Unit]
Description=Tutor-web: Create DB if missing
Requires=mysql.service
Before=tutorweb-zeo.service
After=mysql.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/tutorwebdb

[Install]
RequiredBy=tutorweb-zeo.service
EOF
systemctl enable tutorwebdb

######### Install Tutorweb

adduser --system tutorweb

apt install -y build-essential git python-virtualenv python-dev python-tk \
    libxml2-dev libxslt-dev zlib1g-dev gfortran libjpeg-dev \
    libmariadbclient-dev libmariadb-dev-compat

# https://github.com/DefectDojo/django-DefectDojo/issues/407
sed '/st_mysql_options options;/a unsigned int reconnect;' /usr/include/mysql/mysql.h -i.bkp

git clone git://github.com/tutor-web/tutorweb.buildout /srv/tutorweb.buildout

cat <<'EOF' > /srv/tutorweb.buildout/buildout.cfg
[buildout]
extends = cfgs/production.cfg
always-checkout = false
parts +=
    replicate-dump
    replicate-dump-mkdir
parts -=
    supervisor
    supervisor-crontab
    logrotate-conf
    logrotate-crontab
eggs +=
    MySQL-python
quizdb-url = mysql+mysqldb://tw_quizdb:${passwords:mysql}@localhost/tw_quizdb?charset=utf8
quizdb-coin-pass = ${passwords:smlyrpc}
quizdb-coin-walletpass = ${passwords:smlywallet}
quizdb-coin-captcha-key = none

[zeo]
zeo-log-custom = 

[instance]
user = admin:${passwords:admin}
event-log = disable
access-log = disable
z2-log = disable
EOF

cat <<EOF >> /srv/tutorweb.buildout/buildout.cfg

[passwords]
admin = ${TWPASS}
mysql = ${MYSQLTUTPASS}
smlyrpc = ${RPCPASS}
smlywallet = ${WALLETPASS}
EOF

# Bind-mount /var to global /var/local
mkdir -p /var/local/tutorweb
mkdir -p /srv/tutorweb.buildout/var
mount --bind /var/local/tutorweb /srv/tutorweb.buildout/var

[ -f /twpreload/tutorweb.tar.bz2 ] && {
    tar -jxf /twpreload/tutorweb.tar.bz2 -C /var/local/tutorweb/
    rm /twpreload/tutorweb.tar.bz2
}
chown -R tutorweb /var/local/tutorweb /srv/tutorweb.buildout/var

for f in lib include share bin local eggs src parts develop-eggs; do
    mkdir "/srv/tutorweb.buildout/$f"
    chown tutorweb "/srv/tutorweb.buildout/$f"
done

for f in .mr.developer.cfg; do
    touch "/srv/tutorweb.buildout/$f"
    chown tutorweb "/srv/tutorweb.buildout/$f"
done

# To create .installed.cfg
chown tutorweb /srv/tutorweb.buildout

(cd /srv/tutorweb.buildout \
    && sudo -ututorweb python -m virtualenv . \
    && sudo -ututorweb ./bin/pip install -r requirements.txt \
    && sudo -ututorweb ./bin/buildout; )

# Remove references to geogebra, which won't work
sed -i '/cdn.geogebra.org/d' /srv/tutorweb.buildout/src/tutorweb.quiz/tutorweb/quiz/resources/*.html

cat <<'EOF' > /etc/systemd/system/tutorweb-zeo.service
[Unit]
Description=Tutor-web: ZEO server

[Service]
Type=simple
ExecStart=/srv/tutorweb.buildout/bin/zeo fg
WorkingDirectory=/srv/tutorweb.buildout/bin
User=tutorweb
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable tutorweb-zeo.service

cat <<'EOF' > /etc/systemd/system/tutorweb-instance@.service
[Unit]
Description=Tutor-web: Instance %I
PartOf=tutorweb-zeo.service
After=tutorweb-zeo.service

[Service]
Type=simple
ExecStart=/srv/tutorweb.buildout/bin/instance%i fg
WorkingDirectory=/srv/tutorweb.buildout/bin
User=tutorweb
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=tutorweb-zeo.service
EOF
systemctl enable tutorweb-instance@1.service
systemctl enable tutorweb-instance@2.service
systemctl enable tutorweb-instance@3.service
systemctl enable tutorweb-instance@4.service

mkdir -p /etc/nginx/sites-available ; cat <<'EOF' > /etc/nginx/sites-available/tutor-web
upstream plone {
  # TODO: nginx doesn't support this yet(need 1.7.2) hash $remote_addr$cookie___ac consistent;
  ip_hash;

  server 127.0.0.1:8181;  # Can be marked as "down"
  server 127.0.0.1:8182;
  server 127.0.0.1:8183;
  server 127.0.0.1:8184;
}

server {
  listen [::]:80;
  listen      80;
  server_name tutor-web.eias.lan *.tutor-web.net;

  location ~ ^/manage {
    deny all;
  }

  # Lets-encrypt
  location /.well-known/acme-challenge {
    root /tmp/acme-challenge;
  }

  location /local-dumps {
      root /var/local/tutorweb;

      autoindex on;
      autoindex_exact_size off;
      autoindex_format html;
      autoindex_localtime on;
  }

  location / {
    proxy_pass http://plone/VirtualHostBase/$scheme/$host:$server_port/tutor-web/VirtualHostRoot$request_uri;
    proxy_cache off;
  }
}
EOF
mkdir -p /etc/nginx/sites-enabled ; ln -rs /etc/nginx/sites-available/tutor-web /etc/nginx/sites-enabled/tutor-web

cat <<EOF >> /srv/eias.lan/www/index.html
<div class="links">
  <a href="http://tutor-web.eias.lan/++resource++tutorweb.quiz/start.html">Continue your Tutor-Web tutorials</a>
  <a href="http://tutor-web.eias.lan">Find other Tutor-web content</a>
</div>
EOF

cat <<EOF >> /srv/eias.lan/www/status/index.html
<div class="links">
  <a href="http://tutor-web.eias.lan/local-dumps/">Get tutor-web dump files</a>
</div>
EOF
