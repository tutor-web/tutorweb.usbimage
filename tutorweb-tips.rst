Tutor-web hints and tips
^^^^^^^^^^^^^^^^^^^^^^^^

Changing Plone admin password
=============================

Can't be done through the plone interface, use ZMI::

    http://localhost:8189/acl_users/users/manage_users?user_id=admin&passwd=1


Copying plone users from one Data.fs to another
===============================================#

The following script can:-

* Export / import users to a pickle
* Create users from a CSV list of userid / password / fullname

Copy the code under a ``./bin/instance-debug fg`` prompt.

    import cPickle
    import csv
    import transaction
    from zope.component.hooks import setSite
    from Products.CMFCore.utils import getToolByName
    setSite(app['tutor-web'])
    site = app['tutor-web']
    pas = site.acl_users
    users = pas.source_users
    mtool = site.portal_membership
    def create_user(uid, pwd, fullName=None, email=None):
        rtool = getToolByName(site, 'portal_registration')
        if not(mtool.getMemberById(uid)) and uid not in ignores:
            print "Creating %s" % uid
            rtool.addMember(uid, pwd, properties=dict(
                email=email or 'education.in.a.suitcase@gmail.com',
                username=uid,
                fullname=fullName,
                accept=True,
            ))

    def export_users(filename='/tmp/out.blob'):
        result = dict(users._user_passwords)
        # TODO: Emails too
        f = open(filename, 'w')
        cPickle.dump(result, f)
        f.close()

    def import_user_file(filename='newusers.txt'):
        c = csv.reader(open(filename, 'r'), delimiter=';', quoting=csv.QUOTE_NONE)
        for (fullName, uid, pwd, eMail) in c:
            create_user(uid, pwd, fullName, eMail)

    def import_users(filename='/tmp/out.blob'):
        f = open(filename)
        res = cPickle.load(f)
        f.close()
        for uid, pwd in res.items():
            create_user(uid, pwd)

    ignores=[]
    # Do one of...
    # export_user()
    # import_users()
    # import_user_file()
    transaction.commit()
