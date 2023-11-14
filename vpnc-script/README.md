# vpnc-script workaround

Provides a workaround for problems with setting DNS configurations with the default vpnc-script.

This copy of the vpnc-script provided with OpenConnect is only uploaded here for illustrative purposes.


## Credit

- © 2005-2012 Maurice Massar, Jörg Mayer, Antonio Borneo et al.
- © 2009-2022 David Woodhouse ([email](mailto:dwmw2@infradead.org)), Daniel Lenski ([email](mailto:dlenski@gmail.com)) et al.

To this subfolder, the GPLv2 license applies; as specified in the vpnc-script itself.


## Purpose

My installation of OpenConnect has had problems setting the DNS servers after establishing the VPN connection, outputting the error "... is not a recognized network service".<br />
This is not an unknown problem as can be seen in [this open GitLab issue](https://gitlab.com/openconnect/vpnc-scripts/-/issues/45).


## The workaround

This is the code block in `vpnc-script_orig` responsible for the error:
```shell
# For newer MacOS versions it is needed to set DNS
ACTIVE_INTERFACE=`route -n get default | grep interface | awk '{print $2}'`
ACTIVE_NETWORK_SERVICE=`networksetup -listnetworkserviceorder | grep -B 1 "$ACTIVE_INTERFACE" | head -n 1 | awk '/\([0-9]+\)/{ print }'|cut -d " " -f2-`
networksetup -setdnsservers "$ACTIVE_NETWORK_SERVICE" $INTERNAL_IP4_DNS
```

The problem is that `$ACTIVE_NETWORK_SERVICE` will be empty and thus result in a failed call to `networksetup` to update the DNS servers.

The workaround involves *hardcoding* the `Wi-Fi` device as the active network service.<br />
**While this is true 100% of the time on my machine (running macOS Ventura), this may not be the case for you and thus make the workaround not applicable to you.**

This is the same code block in `vpnc-script` after the workaround:
```shell
# For newer MacOS versions it is needed to set DNS
ACTIVE_INTERFACE=`route -n get default | grep interface | awk '{print $2}'`
# this line is not working, as utunX (or even enX) interfaces cannot be a "network service"
# ACTIVE_NETWORK_SERVICE=`networksetup -listnetworkserviceorder | grep -B 1 "$ACTIVE_INTERFACE" | head -n 1 | awk '/\([0-9]+\)/{ print }'|cut -d " " -f2-`
ACTIVE_NETWORK_SERVICE="Wi-Fi"
networksetup -setdnsservers "$ACTIVE_NETWORK_SERVICE" $INTERNAL_IP4_DNS
```


## Setup

If this problem also occurs on your machine, you can switch out the vpnc-script with my version with the workaround.<br />
**Please do double-check all commands as your install may differ!**

1. Backup the existing `vpnc-script`:
```shell
sudo mv /usr/local/etc/vpnc/vpnc-script /usr/local/etc/vpnc/vpnc-script_orig
```
2. Copy the tweaked `vpnc-script`:
```shell
sudo cp /path/to/download/of/tweaked/script /usr/local/etc/vpnc/vpnc-script
```
3. Make sure it is executable:
```shell
sudo chmod +x /usr/local/etc/vpnc/vpnc-script
```
4. Check if the tweak is still applied or even needed when updating OpenConnect
