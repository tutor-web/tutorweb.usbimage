apt-get install -y wireless-tools hostapd firmware-iwlwifi

mkdir -p /etc/hostapd ; cat <<'EOF' > /etc/hostapd/wlan0.conf
interface=wlan0
# "g" simply means 2.4GHz band
hw_mode=g
# the channel to use
channel=10
# limit the frequencies used to those allowed in the country
ieee80211d=1
# the country code
country_code=KE
# 802.11n support
ieee80211n=1
# QoS support, also required for full speed on 802.11n/ac/ax
wmm_enabled=1

# 1=wpa, 2=wep, 3=both
auth_algs=1
# WPA2 only
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP

ssid=tutorweb-box
wpa_passphrase=tutorweb-box
EOF

cat <<'EOF' > /etc/network/interfaces.d/wifiap
iface wlan0 inet manual
    up systemctl start hostapd@wlan0.service
    down systemctl stop hostapd@wlan0.service

allow-hotplug wlan0
EOF

# Don't use global hostapd, start individual ones when needed
systemctl disable hostapd
