Huawei E3131 USB 3G modems
^^^^^^^^^^^^^^^^^^^^^^^^^^

This is a small 3G modem with an external antenna port.

It can function in various modes, and which are available depends on the firmware:

* A network device with a web interface
* A QMI interface ``/dev/cdc-wdm0`` and network device.
* Serial ports

We want the first, since then all the NUC has to do is request an IP, and leave the 3G management to the modem. However only some firmwares seem to support this.

Miscallaneous notes
-------------------

https://zedt.eu/tech/hardware/switch-huawei-e3131-hilink-modem-mode/

  AT^SETPORT?  – will display the current mode
  AT^SETPORT=? – will display available modes
  AT^SETPORT="A1,A2;1,2,3"  – will set modem only
  AT^SETPORT="A1,A2;1,16,3,2,A1,A2" – will set a different mode (this is my modem’s default mode)


https://www.geekzone.co.nz/forums.asp?forumid=85&topicid=143639

  Reflash with non-hilink firmware

https://github.com/knq/hilink

  hi-link background

https://wiki.dd-wrt.com/wiki/index.php/3G_/_3.5G#Huawei

  DD-WRT-supported modems

Switching configuration mode

  # Was 3, did
  echo 1 > /sys/bus/usb/devices/1-3/bConfigurationValue
  # ...now won't go back.

http://www.embeddedpi.com/documentation/3g-4g-modems/raspberry-pi-sierra-wireless-mc7304-modem-qmi-interface-setup

  .. Have to be connected before network interface will do 'owt?

https://lwn.net/Articles/568867/

  Huawei E3131: this device doesn't accept NDIS setup requests unless they're 
  sent via the embedded AT channel exposed by this driver.
  So actually we gain funcionality in this case!

https://www.linuxquestions.org/questions/linux-wireless-networking-41/help-using-3g-usb-dongle-through-wwan-interface-rather-than-ppp-4175537653/

  AT^NDISDUP=1,1,"giffgaff.com" should be enough to connect
