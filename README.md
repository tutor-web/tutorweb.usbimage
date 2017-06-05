# Prerequisites

    apt-get install qemu-user-static multistrap libguestfs-tools uidmap binfmt-support

    git submodule update --init

    echo "tutor:$PASSWORD" > twpasswd

    ./bin/brickstrap all

# Post startup

    ./bin/qemu --nogrub output/images/output-*-default.img

    mount -o remount,rw /
    dpkg-reconfigure openssh-server
    apt-get update
    apt-get install -t jessie-backports e2fsprogs nginx
    apt-get install mysql-server libmysqlclient-dev shellinabox
    update-initramfs
    update-grub
    grub-install /dev/sda

# Resizing stick

    fdisk -c=dos /dev/sdb
    resize2fs /dev/sdb1

# Adding kiwix images

    wget -O /srv/kiwix -c http://.....zim
    kiwix-index /srv/kiwix/math.stackexchange.com_en_all_2017-05.zim /srv/kiwix/
    kiwix-manage /srv/kiwix/library.xml add /srv/kiwix/math.stackexchange.com_en_all_2017-05.zim 
