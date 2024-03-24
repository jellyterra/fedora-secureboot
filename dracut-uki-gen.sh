#!/bin/bash

set -e

kernel=$(uname --kernel-release)
kernel_cmdline=$(cat /proc/cmdline)

if [ ! -z $1 ]
then
    kernel=$1
fi

. /etc/os-release

efi=/boot/efi/EFI/${kernel}.efi

arch=$(uname -m)

case $arch in
    aarch64 | aarch64_be | armv8l | armv8b)
        arch=aa64
        ;;
    arm)
        arch=arm
        ;;
    x86_64)
        arch=x64
        ;;
    i386)
        arch=ia32
        ;;
    *)
        echo "MACHINE_TYPE_SHORT_NAME of $arch is undefined"
        exit 1
        ;;
esac

echo "Kernel version: $kernel"
echo "Kernel cmdline: $kernel_cmdline"
echo "Generating unified kernel image: $efi"

dracut -f \
    --kernel-cmdline "$kernel_cmdline" \
    --uefi-stub /lib/systemd/boot/efi/linux${arch}.efi.stub \
    --uefi $efi

echo "Adding boot entry to UEFI"

efibootmgr \
    -L "$NAME $VERSION_ID $kernel" \
    --loader $efi \
    --create
