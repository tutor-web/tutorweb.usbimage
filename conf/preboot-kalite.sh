#!/bin/sh -eu
# Run in ~chroot env on image creation

[ -f /var/local/kalite-bundle.deb ] && dpkg -i /var/local/kalite-bundle.deb
[ -d /var/kalite ] && {
    mv /var/kalite /var/kalite.default
    ln -s /var/local/var/kalite /var/kalite
    echo "/var/kalite/.kalite" > /etc/ka-lite/home
}
