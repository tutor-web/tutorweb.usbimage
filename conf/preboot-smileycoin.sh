#!/bin/sh
# Run in ~chroot env on image creation
set -eu

apt-get install -y git \
    build-essential pkg-config \
    autoconf automake autotools-dev libtool \
    libdb++-dev libboost-all-dev \
    libssl-dev
adduser --system smly

git clone git://github.com/smileycoin/smileyCoin /srv/smileycoin
(cd /srv/smileycoin && ./autogen.sh && ./configure && make && ./install.sh)

cat <<'EOSH' >> /usr/local/sbin/smileycoin-setup
#!/bin/sh

exit 0
EOSH
chmod +x /usr/local/sbin/smileycoin-setup

mkdir -p /etc/systemd/system/smly.service.d; cat <<'EOF' > /etc/systemd/system/smly.service.d/override.conf
[Service]
ExecStartPre=/usr/local/sbin/smileycoin-setup
EOF

# TODO:
# sudo -u smly /srv/tutorweb.smileycoin/src/smileycoind \
#     -datadir=/var/lib/smly getnewaddress ""
# sudo -u smly /srv/tutorweb.smileycoin/src/smileycoind \
#     -datadir=/var/lib/smly encryptwallet (key)
# TODO: Write wallet pwd to conf
