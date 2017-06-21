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

    ./bin/stick /dev/sda fill_stick

# Adding kiwix images

    wget -O /srv/kiwix -c http://.....zim

    sudo -u 'ka-lite' kalite manage setup

# Copying plone users from one Data.fs to another

    import cPickle

    def export(self):
        pas = self.acl_users
        users = pas.source_users
        passwords = users._user_passwords
        result = dict(passwords)
        f = open('/tmp/out.blob', 'w')
        cPickle.dump(result, f)
        f.close()
        return "done"

    def import_users(self):
        pas = self.acl_users
        users = pas.source_users
        f = open('/tmp/out.blob')
        res = cPickle.load(f)
        f.close()
        for uid, pwd in res.items():
            if not users.getUser(uid):
                users.addUser(uid, uid, pwd)
        return "done"

    import_users(app['tutor-web'])

# Changing Plone password

    http://eias.lan:8189/acl_users/users/manage_users?user_id=admin&passwd=1
