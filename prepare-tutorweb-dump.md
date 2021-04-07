* Make sure sync_all can run before dumping
* tar -jcvf dumpforbox.tar.bz2 var/blobstorage var/filestorage
* untar into twpreload/
* Remove all existing users

    ./bin/instance-debug debug
    import transaction
    from zope.component.hooks import setSite
    from Products.CMFCore.utils import getToolByName
    setSite(app['tutor-web'])
    site = app['tutor-web']
    mtool = site.portal_membership
    mtool.deleteMembers(mtool.listMemberIds())
    transaction.commit()
  
* Update mail config to localhost:9025 in @@mail-controlpanel
* Enable "Let users select their own passwords"
* Update admin password: http://localhost:8189/acl_users/users/manage_users?user_id=admin&passwd=1
* Change front-page links
* Pack image

  ./bin/zeopack -D1
