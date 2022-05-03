# Education-in-a-Suitcase image builder

This is a collection of scripts to build a image for EIAS, using
[virt-builder](https://developer.fedoraproject.org/tools/virt-builder/about.html).

# Prerequisites

Under debian:

    apt install libguestfs-tools

# Configuration

Components of the image can be added/removed by altering the ``build-image`` script.

## Configuring admin users

Create a file ``twpreload/twadmins``, with colon-seperated usernames and passwords, e.g:

```
cat <<EOF > twpreload/twadmins
user1:pwd1
user2:pwd2
EOF
```

## Restricting internet access

Create a ``twpreload/twhosts`` file with a white list of hosts to connect to, separated by carrage return.

## phonehome reverse-SSH access

The phonehome service will ssh to a given host, configured in ``twpreload/phonehome/config``, for example:

```
Host phonehome
    User phonehome
    HostName phonehome.server.net
```

An SSH key will be added to the image, and it's public half available at ``twpreload/phonehome/id_rsa.pub``.

## Pre-baked kiwix content

As well as separate partitions, kiwix content files can be baked into the image.
Download [.zim files from here](https://wiki.kiwix.org/wiki/Content_in_all_languages) and add it to the
``twpreload/kiwix/`` directory. .zim files can also be added into a ``twextra``
or ``twdata`` partitions, in a ``kiwix`` directory.

## Tutor-web content

You need to get a tarball of tutorweb content, and place it at ``twpreload/tutorweb.tar.bz2``.

On first start you also need to run sync_all to populate the database, e.g:

    sudo -ututorweb /srv/tutorweb.buildout/bin/sync_all

# Building

Run ``./build-image``. A ``eias.amd64.img`` will be created which can be flashed onto a bootable device.

# Emulating

Run ``sudo ./qemu-setup`` to create network bridge device, then run ``./qemu``
to boot an image in a virtual machine. Run ``./qemu-host`` to start a LiveCD
connected to the server.

You can SSH to the VM with ``ssh -p10022 tutor@localhost``.

# Writing to physical media

As well as the main filesystem, the image will also mount any partitions found
with the following label:

* ``twextra``: Read-only partition for e.g. kiwix content
* ``twdata``: Read-write partition where tutor-web results are stored.

After writing the image to a disk, you can use unpartitioned space by creating
an extra partition and using one of the labels above when formatting, e.g:

    mkfs.ext4 -L twdata /dev/sdc2

# Suggested hardware:

* [APU2](user-guide/assembly-apu2.md)
