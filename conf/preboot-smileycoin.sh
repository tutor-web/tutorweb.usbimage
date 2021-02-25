#!/bin/sh
# Run in ~chroot env on image creation
set -eu

cat <<'EOSH' >> /usr/local/sbin/smileycoin-setup
#!/bin/sh

[ -d /var/lib/smly ] || {
  mkdir -p /var/local/var/lib/smly
  chown smly:staff /var/local/var/lib/smly
}
[ -f /var/lib/smly/smileycoin.conf ] || {
    RPCPASS="$(xxd -ps -l 22 /dev/urandom)"
    echo "rpcuser=smileycoinrpc" > /var/lib/smly/smileycoin.conf
    echo "rpcpassword=${RPCPASS}" >> /var/lib/smly/smileycoin.conf
}
EOSH
chmod +x /usr/local/sbin/smileycoin-setup
