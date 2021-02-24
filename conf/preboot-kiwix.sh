#!/bin/sh -eu
# Run in ~chroot env on image creation

exit 0  # TODO:
cat <<'EOSH' >> /usr/local/sbin/kiwix-setup

##### kiwix
echo "" > /run/kiwix-library.xml
ls -1 \
    /srv/kiwix/*.zim \
    /srv/kiwix/*.zimaa \
    /twpreload/kiwix/*.zim \
    /twpreload/kiwix/*.zimaa \
    /twdata/kiwix/*.zim \
    /twdata/kiwix/*.zimaa \
    | xargs -L1 kiwix-manage /run/kiwix-library.xml add

EOSH
