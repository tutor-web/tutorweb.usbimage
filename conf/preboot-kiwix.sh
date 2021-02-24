#!/bin/sh -eu
# Run in ~chroot env on image creation

cat <<'EOSH' >> /usr/local/sbin/sethost

##### kiwix
echo "" > /run/kiwix-library.xml
ls -1 \
    /srv/kiwix/*.zim \
    /srv/kiwix/*.zimaa \
    /var/local/srv/kiwix/*.zim \
    /var/local/srv/kiwix/*.zimaa \
    | xargs -L1 kiwix-manage /run/kiwix-library.xml add

EOSH
