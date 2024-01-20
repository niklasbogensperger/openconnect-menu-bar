#!/usr/bin/env bash

#########################################################
# CREDIT #
#########################################################

# Credit for original concept and initial work to: Jesse Jarzynka
#  - https://github.com/matryer/xbar-plugins/blob/7afadc2d29270c47fe09df4cabc8c29206bd419d/Network/vpn_advanced.sh
# Credit for modifications and improvement work to: Ventz Petkov
#  - https://github.com/ventz/openconnect-gui-menu-bar/blob/6bda0e18b12493b5c727f6cfca636e1455f23d56/openconnect.sh
# This file is based on the 2023-11-08 version of Ventz' script available at the link above

# Credit for the menu bar icons to: FreeImages.com/VisualPharm
# Usage of the content in a project such as this is permitted according to the FreeImages license (May 2022 version)
#  - License: https://www.freeimages.com/license
#  - Disconnected icon: https://www.freeimages.com/icon/disconnected-5668900
#  - Connected icon: https://www.freeimages.com/icon/connected-5669666


#########################################################
# CHANGELOG #
#########################################################

### 2023-11-14
### Version 1.0 (restarted versioning) by Niklas Bogensperger
# - added proper adaptive (light/dark mode compatible) icon
# - added configuration and status details in dropdown menu
# - added uptime counter
# - added SwiftBar metadata for some improved functionality (backwards compatible with xbar (formerly BitBar))
# - added customization of the VPN name (short/long title)
# - modularized the code a bit
# - restructured the customization instructions
# - tweaked the sleep timer in the connect/disconnect function
# - removed 2FA code as it was unneeded for my use case
# - miscellaneous smaller tweaks and fixes

### 2023-11-08
### Base version by Ventz Petkov (see above)


#########################################################
# XBAR / SWIFTBAR METADATA #
#########################################################

# <xbar.title>OpenConnect Helper</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Niklas Bogensperger</xbar.author>
# <xbar.author.github>niklasbogensperger</xbar.author.github>
# <xbar.desc>Establish VPN connections via OpenConnect and monitor connection status</xbar.desc>
# <xbar.dependencies>openconnect</xbar.dependencies>
# <xbar.abouturl>https://github.com/niklasbogensperger/openconnect-menu-bar</xbar.abouturl>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>


#########################################################
# CONFIGURATION STEPS #
#########################################################

### Step 1
### Pointing to the openconnect (and optional oath-toolkit) installation
# a) Install the openconnect binary with a method of your choice, e.g. the homebrew package manager:
#    `brew install openconnect`
# b) Make sure the binary is located here, otherwise change the path:
#    Another location with homebrew on M series Macs is e.g. /opt/homebrew/bin/openconnect
VPN_EXECUTABLE=/usr/local/bin/openconnect
##### Optional as required by the VPN server - see also step 8
# c) Install the oath-toolkit binary with a method of your choice, e.g. the homebrew package manager:
#    `brew install oath-toolkit`
# d) Make sure the binary is located here, otherwise change the path:
#    Another location with homebrew on M series Macs is e.g. /opt/homebrew/bin/oathtool
OATHTOOL_EXECUTABLE=/usr/local/bin/oathtool

### Step 2
### Updating the sudo configuration so the script can run the relevant commands
# a) Create a file somewhere with the following content, e.g. here named "openconnect_nopasswd" but pick whatever name you prefer:
#    (Note: replace "<username>" with your username and "$VPN_EXECUTABLE" with the value from step 1)
#    <username> ALL=(ALL) NOPASSWD: $VPN_EXECUTABLE
#    <username> ALL=(ALL) NOPASSWD: /usr/bin/killall -2 openconnect
# b) Check that the file's syntax is error-free by running:
#    `visudo -cf <path to file>`
# c) Copy the file to the /etc/sudoers.d/ directory (sudo is needed so the file is owned by root):
#    `sudo cp <path to file> /etc/sudoers.d/openconnect_nopasswd`
# d) Set the appropriate file permissions:
#    `sudo chmod 0440 /etc/sudoers.d/openconnect_nopasswd`
# e) Verify file permission and ownership again (output should contain "-r--r-----" and "root"):
#    `ls -l /etc/sudoers.d/openconnect_nopasswd`

### Step 3
### Specifying basic parameters of the VPN connection
# a) Specify the VPN host address:
VPN_HOST='https://vpn.example.tld'
# b) Specify the kind of VPN protocol used by the server (default: Cisco AnyConnect):
#    (see https://www.infradead.org/openconnect/protocols.html for a list of supported options)
VPN_PROTOCOL='anyconnect'
# c) Specify the User Agent to be used by openconnect:
#    (Leave this value as-is when using AnyConnect due to this issue: https://gitlab.com/openconnect/openconnect/-/issues/544)
VPN_USER_AGENT='AnyConnect'

### Step 4
### Specifying the user-specific login details
# a) Specify the user group, if used:
VPN_GROUP='example-group'
# b) Specify the username:
VPN_USERNAME='user@vpn.example.tld'

### Step 5
### Securely storing the login password in the system keychain

# **CAUTION** - While this is no different than saving a password for "autofill",
#               this does mean that your password must be saved to the system keychain
#               and will be retrieved by this script for use with openconnect.
#               All of openconnect, SwiftBar, and the code you are currently reading
#               and modifying are open source and should not be doing anything nefarious;
#               yet still:
# PROCEED AT YOUR OWN RISK

# a) Open "Keychain Access" (in /Applications/Utilities/)
# b) Select the "login" keychain in the sidebar (in the category "Default Keychains")
# c) Select the "Passwords" category in the main window
# d) Select File -> New Password Item... or click the corresponding icon in the toolbar
# e) For "Keychain Item Name" use the value from "$VPN_HOST"
# f) For "Account Name" use the value from "$VPN_USERNAME"
# g) For "Password" enter your password
# h) Change the following value to either "find-internet-password" or "find-generic-password", depending on what is displayed in Keychain Access
PASSWORD_CMD_KIND='find-internet-password'
# i) When prompted by macOS that the script wants to access this keychain item, select "Always allow"

### Step 6
### Customize the name of the connection profile
# a) The short title will be displayed in the menu bar itself, next to the icon; you can also leave it blank and only the icon will be displayed
#    (Note: the spacing can be tight, so you can place leading and trailing spaces and they will not be trimmed)
SHORT_TITLE=''
# b) The long title will be displayed in the dropdown text
#    (Note: leading and trailing spaces will be trimmed)
LONG_TITLE='VPN'

### Step 7
### Specify the network interface to be used in the network configuration
# Leave this unchanged to avoid collisions with other VPN configurations you may have on your system
# Modify if you know what you are doing (e.g. working with ifconfig)
VPN_INTERFACE='utun99'

##### Optional as required by the VPN server
### Step 8
### Securely storing the 2FA seed in the system keychain

# Proceed only if required, otherwise set this to false and skip this section
TWO_FA_ENABLED=true

if [[ "$TWO_FA_ENABLED" = "true" ]] ; then
# **CAUTION** - While this is no different than saving a password for "autofill",
#               this does mean that your 2FA seed value must be saved to the system keychain
#               and will be retrieved by this script for use with openconnect.
#               All of openconnect, SwiftBar, oath-toolkit, and the code you are currently
#               reading and modifying are open source and should not be doing anything nefarious;
#               yet still:
# PROCEED AT YOUR OWN RISK

# a) Open "Keychain Access" (in /Applications/Utilities/)
# b) Select the "login" keychain in the sidebar (in the category "Default Keychains")
# c) Select the "Passwords" category in the main window
# d) Select File -> New Password Item... or click the corresponding icon in the toolbar
# e) For "Keychain Item Name" use the value from "$VPN_HOST", followed immediately by "_2FA"
# f) For "Account Name" use the value from "$VPN_USERNAME"
# g) For "Password" enter your 2FA seed value
# h) Change the following value to either "find-internet-password" or "find-generic-password", depending on what is displayed in Keychain Access
    TWO_FA_CMD_KIND='find-internet-password'
# i) The command below assumes a base32-encoded ("-b") time-based one-time password ("--totp")
#    (see the oath-toolkit documentation for other options depending on your setup)
    TWO_FA_OTP="$($OATHTOOL_EXECUTABLE -b --totp $(security $TWO_FA_CMD_KIND -wl ${VPN_HOST}_2FA))"
# j) Specify the FORM:OPTION naming of the form field where the OTP should be entered
#    (this can be found out by starting openconnect interactively in the shell with the "--dump-http-traffic -vvv" flag)
    TWO_FA_FORM_FIELD='main:secondary_password'
# k) When prompted by macOS that the script wants to access this keychain item, select "Always allow"

### do not change this block 
    VPN_2FA_STRING="--form-entry=${TWO_FA_FORM_FIELD}=${TWO_FA_OTP}"
else
    VPN_2FA_STRING=''
fi


#########################################################
# SCRIPT CODE #
#########################################################

# base64 encoded string of the menu bar icon
CONNECTED_ICON='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'
DISCONNECTED_ICON='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'


# Checks whether the VPN network interface is active
check_status() {
    [ -n "$(ifconfig | grep -A3 $VPN_INTERFACE | grep inet)" ]
}


# Calculates the uptime of the connection according to the start time of the openconnect process
get_uptime() {
    START_TIME=$(ps -o lstart -p $(pgrep -x openconnect) | tail -n 1)
    START_TIME_EPOCH_SECONDS=$(date -jf "%c" "$START_TIME" +"%s")
    CURRENT_TIME_EPOCH_SECONDS=$(date +"%s")
    TIME_DIFFERENCE=$((CURRENT_TIME_EPOCH_SECONDS - START_TIME_EPOCH_SECONDS))

    SECONDS_IN_MINUTE=60
    SECONDS_IN_HOUR=3600
    SECONDS_IN_DAY=86400
    DAYS=$((TIME_DIFFERENCE / SECONDS_IN_DAY))
    HOURS=$(( (TIME_DIFFERENCE % SECONDS_IN_DAY) / SECONDS_IN_HOUR ))
    MINUTES=$(( (TIME_DIFFERENCE % SECONDS_IN_HOUR) / SECONDS_IN_MINUTE ))
    SECONDS=$((TIME_DIFFERENCE % SECONDS_IN_MINUTE))

    echo "${DAYS}d ${HOURS}h ${MINUTES}m ${SECONDS}s"
}


# Connects to the VPN server with openconnect with the details specified above
connect_vpn() {
    echo "$(security $PASSWORD_CMD_KIND -wl $VPN_HOST)" | sudo $VPN_EXECUTABLE --protocol=$VPN_PROTOCOL --useragent=$VPN_USER_AGENT -g $VPN_GROUP -u $VPN_USERNAME $VPN_2FA_STRING --passwd-on-stdin -i $VPN_INTERFACE $VPN_HOST &> /dev/null &

    # Wait for connection so menu item refreshes instantly
    until check_status; do sleep 0.3; done
}


# Terminates the openconnect process and thus disconnects the VPN connection
disconnect_vpn() {
    sudo killall -2 openconnect

    # Wait for disconnection so menu item refreshes instantly
    while check_status; do sleep 0.3; done
}


case "$1" in
    connect)
        connect_vpn
        ;;
    disconnect)
        disconnect_vpn
        ;;
    *)
        if check_status; then
            echo "${SHORT_TITLE}| templateImage=$CONNECTED_ICON trim=false"
            echo '---'
            echo "Disconnect $LONG_TITLE | bash='$0' param1=disconnect terminal=false refresh=true"
            echo '---'
            echo "Status: Connected | disabled=true color=green"
            echo "Uptime: $(get_uptime) | disabled=true"
            echo '---'
            echo "Host: $VPN_HOST | disabled=true"
            echo "User: $VPN_USERNAME | disabled=true"
            echo "Group: $VPN_GROUP | disabled=true"
            echo "Protocol: $VPN_PROTOCOL | disabled=true"
            echo "Interface name: $VPN_INTERFACE | disabled=true"
        else
            echo "${SHORT_TITLE}| templateImage=$DISCONNECTED_ICON trim=false"
            echo '---'
            echo "Connect $LONG_TITLE | bash='$0' param1=connect terminal=false refresh=true"
            echo '---'
            echo "Status: Disconnected | disabled=true color=red"
            echo '---'
            echo "Host: $VPN_HOST | disabled=true"
            echo "User: $VPN_USERNAME | disabled=true"
            echo "Group: $VPN_GROUP | disabled=true"
            echo "Protocol: $VPN_PROTOCOL | disabled=true"
            echo "Interface name: $VPN_INTERFACE | disabled=true"
        fi
        ;;
esac
