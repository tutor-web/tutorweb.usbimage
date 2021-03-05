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
``twpreload/kiwix/`` directory.

# Building

Run ``./build-image``. A ``eias.amd64.img`` will be created which can be flashed onto a bootable device.

# Emulating

Run ``./qemu`` to boot an image in a virtual machine.

