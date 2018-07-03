# jul/03/2018 19:58:07 by RouterOS 6.42.1
# software id = 4MPK-8MEB
#
# model = RouterBOARD cAP L-2nD
# serial number = 79300710B3FE
/interface bridge
add comment=defconf fast-forward=no name=bridge
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20/40mhz-Ce \
    country=kenya disabled=no distance=indoors frequency=auto mode=ap-bridge \
    ssid=tutorweb-box wireless-protocol=802.11
/interface wireless security-profiles
set [ find default=yes ] authentication-types=wpa2-psk mode=dynamic-keys \
    supplicant-identity=MikroTik wpa-pre-shared-key=tutorweb-box \
    wpa2-pre-shared-key=tutorweb-box
/ip hotspot profile
set [ find default=yes ] html-directory=flash/hotspot
/interface bridge port
add bridge=bridge comment=defconf hw=no interface=ether1
add bridge=bridge comment=defconf interface=wlan1
/ip address
add address=192.168.88.1/24 comment=defconf interface=bridge network=\
    192.168.88.0
/ip dhcp-client
add dhcp-options=hostname,clientid disabled=no interface=bridge
/system clock
set time-zone-name=Europe/London
/system identity
set name=tutorweb-box-cap-lite
/system routerboard settings
set silent-boot=no
