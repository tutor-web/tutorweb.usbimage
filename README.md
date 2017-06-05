# Prerequisites

    apt-get install qemu-user-static multistrap libguestfs-tools uidmap binfmt-support

    git submodule update --init

    echo "tutor:$PASSWORD" > twpasswd

    ./bin/brickstrap all

# Post startup

    ./bin/qemu --nogrub output/images/output-*-default.img

    # Login as tutor
    sudo /usr/local/sbin/finish-installation

# Resizing stick

    fdisk -c=dos /dev/sdb
    resize2fs /dev/sdb1

# Adding kiwix images

    wget -O /srv/kiwix -c http://.....zim
