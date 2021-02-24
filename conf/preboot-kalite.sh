#!/bin/sh -eu
# Run in ~chroot env on image creation

[ -f /twpreload/kalite-bundle.deb ] && dpkg -i /twpreload/kalite-bundle.deb
[ -d /var/TODOkalite ] && {
    # TODO: Wrong
    mv /var/kalite /var/kalite.default
    ln -s /var/local/var/kalite /var/kalite
    echo "/var/kalite/.kalite" > /etc/ka-lite/home
}
