Using Mirkotik routers for EiaS
===============================

We currently have the following accesspoints:

* mAP-2ND
* cAP Lite

Most of the below applies to both.

Initial reset
-------------

* Hold down reset button
* Power on, wait 5 seconds (USR should blink)
* Release
* Connect to ``192.168.88.1`` (there should be a DHCP server running to give you an IP address)

Restoring config
----------------

* Go to http://192.168.88.1/webfig/#Files
* Upload relevant backup file
* Click on file
* Click "Restore" button at top

After reboot, the router's IP address will be requested from whatever network is connected to it's ethernet port.

Manual reconfig
---------------

From the "Quick set" page:

* Choose "WISP AP" (see top of page)
* Network name: tutorweb-box
* Security: WPA2
* Password: (normal)
* Mode: bridge
* Address source: Any
* Router Identity: tutorweb-box-map-2nd
* Password: (admin password)

Go to "WebFig" -> "IP" -> "DHCP Server" and press disable

Then, save the configuration to repository:

* From RouterOS terminal: ``system backup save name=tutorweb-box-``(model)
* Download from http://.../webfig/#Files

Debricking
----------

Visit https://mikrotik.com/download, get
* Base packages for mipsbe
* netinstall

Run netinstall in Windows VM, using a tap0 not user interface

* Make sure windows is using a "home" network
* Make sure dnsmasq is stopped, so it doesn't reply

Configure netinstall to do netboot, give an IP in the same address range.

Restart netintsall, wait for router to appear

* "Keep old configuration"
* Press "install"

* https://blog.ligos.net/2016-12-27/Recover-A-Broken-Mikroik-Device.html

Links
-----

* mAP-2nd quick start: https://i.mt.lv/routerboard/files/mAP-qg.pdf
* RouterOS Manual: https://wiki.mikrotik.com/wiki/Manual:TOC
