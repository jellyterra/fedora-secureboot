#!/bin/bash

set -e

if [ -z "$ESP" ]; then export ESP="/dev/nvme0n1p1"; fi
if [ -z "$KEY" ]; then export KEY="./db.key"; fi
if [ -z "$CERT" ]; then export CERT="./db.crt"; fi
if [ -z "$KERNEL_RELEASE" ]; then export KERNEL_RELEASE="$(uname --kernel-release)"; fi
if [ -z "$KERNEL_CMDLINE" ]; then export KERNEL_CMDLINE="$(cat /proc/cmdline)"; fi

ARCH=$(uname -m)
EFI="/boot/efi/EFI/${KERNEL_RELEASE}.efi"

echo "Architecture: $ARCH"
echo "DB key: $KEY"
echo "DB cert: $CERT"
echo "ESP: $ESP"
echo "EFI target: $EFI"
echo
echo "KERNEL_RELEASE: $KERNEL_RELEASE"
echo "KERNEL_CMDLINE: $KERNEL_CMDLINE"
echo

case "$ARCH" in
    aarch64 | aarch64_be | armv8l | armv8b)
        export ARCH_SHORT=aa64
        ;;
    arm)
        export ARCH_SHORT=arm
        ;;
    x86_64)
        export ARCH_SHORT=x64
        ;;
    i386)
        export ARCH_SHORT=ia32
        ;;
    *)
        echo "MACHINE_TYPE_SHORT_NAME of $ARCH is undefined. You may have to add it to this script manually."
        exit 1
        ;;
esac

echo ">>> Generating UKI"
echo

dracut -f \
    --kver "$KERNEL_RELEASE" \
    --kernel-cmdline "$KERNEL_CMDLINE" \
    --uefi-stub "/lib/systemd/boot/efi/linux${ARCH_SHORT}.efi.stub" \
    --uefi "$EFI"

echo ">>> Signing UKI"

sbsign --key "$KEY" --cert "$CERT" --output "$EFI" "$EFI"

echo
echo ">>> Registering to UEFI boot menu"
echo

. /etc/os-release

efibootmgr \
    -L "$NAME - $KERNEL_RELEASE" \
    --disk "$ESP" \
    --loader "/EFI/${KERNEL_RELEASE}.efi" \
    --create

echo
echo "Done."
