#!/bin/bash

set -o errexit

MY_PROMPT='$ '
MY_YESNO_PROMPT='[Y/n] $ '
usrname=admin
confirm=y
grpname="flirimaging"

if [ "$(id -u)" = "0" ]
then
    echo
    echo "This script will assist users in configuring their udev rules to allow"
    echo "access to USB devices. The script will create a udev rule which will"
    echo "add FLIR USB devices to a group called $grpname. The user may also"
    echo "choose to restart the udev daemon. All of this can be done manually as well."
    echo
else
    echo
    echo "This script needs to be run as root, e.g.:"
    echo "sudo configure_spinnaker.sh"
    echo
    exit 0
fi

echo "Adding new members to usergroup $grpname..." 


# # Show current members of the user group
# users=$(grep -E '^'$grpname':' /etc/group |sed -e 's/^.*://' |sed -e 's/, */, /g')
groupadd -f flirimaging
usermod -a -G flirimaging root
usermod -a -G flirimaging $usrname

# Create udev rule
UdevFile="/etc/udev/rules.d/40-flir-spinnaker.rules"
echo
echo "Writing the udev rules file...";
echo "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"1e10\", GROUP=\"$grpname\"" 1>>$UdevFile
echo "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"1724\", GROUP=\"$grpname\"" 1>>$UdevFile

echo "Do you want to restart the udev daemon?"
echo -n "$MY_YESNO_PROMPT"

if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ] || [ "$confirm" = "yes" ] || [ "$confirm" = "Yes" ] || [ "$confirm" = "" ]
then
    /etc/init.d/udev restart
else
    echo "Udev was not restarted.  Please reboot the computer for the rules to take effect."
    exit 0
fi

echo "Configuration complete."
echo "A reboot may be required on some systems for changes to take effect."
exit 0
