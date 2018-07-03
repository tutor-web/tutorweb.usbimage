# jul/03/2018 17:06:43 by RouterOS 6.42.1
# software id = ZEEL-W4VV
#
# model = RouterBOARD mAP 2nD
# serial number = 850A078A91F7
/interface bridge
add comment=defconf fast-forward=no name=bridge
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20/40mhz-Ce \
    country=kenya disabled=no distance=indoors frequency=auto mode=ap-bridge \
    ssid=tutorweb-box wireless-protocol=802.11
/interface list
add exclude=dynamic name=discover
add name=mactel
add name=mac-winbox
add name=WAN
/interface wireless security-profiles
set [ find default=yes ] authentication-types=wpa2-psk mode=dynamic-keys \
    supplicant-identity=MikroTik wpa-pre-shared-key=tutorweb-box \
    wpa2-pre-shared-key=tutorweb-box
/ip hotspot profile
set [ find default=yes ] html-directory=flash/hotspot
/ip pool
add name=dhcp ranges=192.168.88.10-192.168.88.254
/ip dhcp-server
add address-pool=dhcp authoritative=after-2sec-delay interface=bridge name=\
    defconf
/interface bridge port
add bridge=bridge comment=defconf hw=no interface=ether2
add bridge=bridge comment=defconf interface=wlan1
add bridge=bridge hw=no interface=ether1
/ip neighbor discovery-settings
set discover-interface-list=discover
/interface list member
add interface=ether2 list=discover
add interface=wlan1 list=discover
add interface=bridge list=discover
add interface=bridge list=mac-winbox
add interface=ether1 list=WAN
add interface=ether2 list=mactel
add interface=wlan1 list=mactel
/ip address
add address=192.168.88.1/24 comment=defconf interface=bridge network=\
    192.168.88.0
/ip dhcp-client
add comment=defconf dhcp-options=hostname,clientid disabled=no interface=\
    bridge
/ip dhcp-server network
add comment=defconf gateway=0.0.0.0
/ip dns
set allow-remote-requests=yes
/ip dns static
add address=192.168.88.1 name=router
/ip firewall filter
add action=accept chain=input comment="defconf: accept ICMP" protocol=icmp
add action=accept chain=input comment="defconf: accept established,related" \
    connection-state=established,related
# in/out-interface matcher not possible when interface (ether1) is slave - use master instead (bridge)
add action=drop chain=input comment="defconf: drop all from WAN" \
    in-interface=ether1
add action=fasttrack-connection chain=forward comment="defconf: fasttrack" \
    connection-state=established,related
add action=accept chain=forward comment="defconf: accept established,related" \
    connection-state=established,related
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
# in/out-interface matcher not possible when interface (ether1) is slave - use master instead (bridge)
add action=drop chain=forward comment=\
    "defconf:  drop all from WAN not DSTNATed" connection-nat-state=!dstnat \
    connection-state=new in-interface=ether1
/ip firewall nat
# in/out-interface matcher not possible when interface (ether1) is slave - use master instead (bridge)
add action=masquerade chain=srcnat comment="defconf: masquerade" \
    out-interface=ether1
/system clock
set time-zone-name=Europe/London
/system identity
set name=tutorweb-box-map-2nd
/system routerboard settings
set silent-boot=no
/tool mac-server
set allowed-interface-list=mactel
/tool mac-server mac-winbox
set allowed-interface-list=mac-winbox
