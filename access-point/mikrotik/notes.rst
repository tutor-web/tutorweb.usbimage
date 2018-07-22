Using Mirkotik routers for EiaS
===============================

We currently have the following accesspoints:

* mAP-2ND
* cAP Lite

Most of the below applies to both.

Install via. NetInstall / Debricking
------------------------------------

Firstly try resetting. Hold reset button for 5 seconds whilst turning on, until USR starts flashing.
https://wiki.mikrotik.com/wiki/Manual:Reset_button

Visit https://mikrotik.com/download, get
* Base packages for mipsbe
* netinstall

Run netinstall in Windows VM, using a tap0 not user interface. Make sure windows is using a "home" network

Configure netinstall to do netboot, give an IP in the same address range, e.g. ``172.16.130.99``

Connect to laptop. For mAP devices, use eth1.

Make sure dnsmasq is stopped, so it doesn't reply

Restart device in netinstall mode, hold reset button for at least 15s: https://wiki.mikrotik.com/wiki/Manual:Reset_button

Router should appear in list.

* Select routeros-mipsbe package (no others should be necessary, includes wireless, etc.)
* Select "Configure Script" and choose the .rsc file
* Press "install"

Once the router reboots, set MAC address and password.

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

Configure laptop to listen to ``192.168.88.1``, for example

  ifconfig br0:0 192.168.88.2 netmask 255.255.255.252 up

Connect router to laptop via. network (NB: use eth2 on a mAP device).

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

Go to "WebFig" -> "IP" -> "Addresses" and re-enable ``192.168.88.1/24`` on bridge.

Then, save the configuration to repository:

* From RouterOS terminal: ``system backup save name=tutorweb-box-``(model)
* Download from http://.../webfig/#Files

Also fetch a default configuration script:
* From RouterOS terminal: ``export file=tutorweb-box-map-2nd`` (or whichever model)
* Download from http://.../webfig/#Files

Links
-----

* mAP-2nd quick start: https://i.mt.lv/routerboard/files/mAP-qg.pdf
* RouterOS Manual: https://wiki.mikrotik.com/wiki/Manual:TOC
* https://github.com/haakonnessjoen/MAC-Telnet
* https://blog.ligos.net/2016-12-27/Recover-A-Broken-Mikroik-Device.html
* https://wiki.mikrotik.com/wiki/Manual:Netinstall
