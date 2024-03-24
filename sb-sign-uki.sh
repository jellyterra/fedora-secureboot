#!/bin/bash

set -e

kernel=$(uname --kernel-release)

if [ ! -z $1 ]
then
    kernel=$1
fi

efi=/boot/efi/EFI/${kernel}.efi

echo "Signing unified kernel image: $efi"

sbsign --key db.key --cert db.crt --output $efi $efi
