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

[ -f /var/lib/mysql/tw_quizdb/db.opt ] && exit 0

cat <<EOF | mysql -u root
CREATE DATABASE tw_quizdb;
CREATE USER 'tw_quizdb'@'localhost' IDENTIFIED BY '${MYSQLTUTPASS}';
GRANT ALL PRIVILEGES ON tw_quizdb. * TO 'tw_quizdb'@'localhost';
EOF

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
Description=Create tutor-web DB if missing

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/tutorwebdb

[Install]
WantedBy=tutorweb.service
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

cat <<EOF > /srv/tutorweb.buildout/buildout.cfg
[buildout]
extends = cfgs/production.cfg
always-checkout = false
parts +=
    replicate-dump
    replicate-dump-mkdir
eggs +=
    MySQL-python
quizdb-url = mysql+mysqldb://tw_quizdb:${passwords:mysql}@localhost/tw_quizdb?charset=utf8
quizdb-coin-pass = ${passwords:smlyrpc}
quizdb-coin-walletpass = ${passwords:smlywallet}
quizdb-coin-captcha-key = none

[instance]
user = admin:${passwords:admin}

[passwords]
admin = ${TWPASS}
mysql = ${MYSQLTUTPASS}
smlyrpc = ${RPCPASS}
smlywallet = ${WALLETPASS}
EOF

# Symlink tw's var to the global var
mkdir -p /var/local/tutorweb
ln -fs /var/local/tutorweb /srv/tutorweb.buildout/var
chown tutorweb /var/local/tutorweb

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

# TODO: Copy in bootstrap Data.fs

cat <<'EOF' > /etc/systemd/system/tutorweb.service
[Unit]
Description=Tutor-web
After=network.target

[Service]
ExecStart=/srv/tutorweb.buildout/bin/supervisord
ExecStop=/srv/tutorweb.buildout/bin/supervisorctl $OPTIONS shutdown
ExecReload=/srv/tutorweb.buildout/bin/supervisorctl $OPTIONS reload
User=tutorweb
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable tutorweb.service

cat <<'EOSH' > /usr/local/sbin/tutorweb-setup
#!/bin/sh -eu

EOSH
chmod a+x /usr/local/sbin/tutorweb-setup
