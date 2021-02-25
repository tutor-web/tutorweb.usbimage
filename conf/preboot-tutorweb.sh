#!/bin/sh
# Run in ~chroot env on image creation
set -eu

cat <<EOF | debconf-set-selections -v
mysql-server mysql-server/root_password password ""
mysql-server mysql-server/root_password_again password ""
EOF

apt-get install -y mysql-server libmysqlclient-dev

cat <<'EOF' > /etc/mysql/conf.d/no-error-log.cnf
[mysqld]
general_log = 0
log_error = /tmp/mysql_error.log
EOF

(cd /srv/tutorweb.buildout && sudo -ututorweb ./bin/buildout; )

cat <<'EOSH' > /usr/local/sbin/tutorweb-setup
#!/bin/sh -eu

##### MySQL
[ -d /var/lib/mysql ] || {
    mkdir -p /var/lib/mysql
    [ -e /usr/bin/mysql_install_db ] && /usr/bin/mysql_install_db
}

##### Tutor-web
mkdir -p /var/local/tutorweb.buildout
mkdir -p r/var/local/tutorweb.buildout/var/log
mount -t tmpfs tmpfs /srv/tutorweb.buildout/var/log
[ -f /var/local/tutorweb.buildout/buildout.cfg ] || {
    MYSQLPASS="$(xxd -ps -l 22 /dev/urandom)"
    TWPASS="$(xxd -ps -l 22 /dev/urandom)"
    RPCPASS="$(awk -F= '/rpcpassword\=/ { print $2; }' /var/lib/smly/smileycoin.conf)"
    WALLETPASS="$(xxd -ps -l 22 /dev/urandom)"
    cat <<'EOF' > /var/local/tutorweb.buildout/buildout.cfg
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

[instance]
user = admin:${passwords:admin}

[passwords]
admin = ${TWPASS}
mysql = ${MYSQLPASS}
smlyrpc = ${RPCPASS}
smlywallet = ${WALLETPASS}
EOF
}
EOSH
chmod a+x /usr/local/sbin/tutorweb-setup
