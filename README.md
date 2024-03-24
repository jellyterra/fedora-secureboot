# Fedora SecureBoot Setup Utilities

Build trusted boot on Fedora and even more distributions.

For new Linux user, you'd better to understand how the SecureBoot and the scripts works.

For senior Linux user, you may want to learn more about how the scripts works.

The process is as follows:
```bash
sb-keygen.sh
sb-update-key.sh
dracut-uki-gen.sh
sb-sign-uki.sh
```


## Preparation

Install dependencies
- dracut
- efitools
- openssl
- sbsigntools
- systemd-boot: EFI stub file is required by **dracut**

```bash
dnf install dracut efitools openssl sbsigntools systemd-boot
```

> [!CAUTION]
> Backup your UEFI configuration, ESP and bootloader, have a backup in case the unexpected happens.

> [!NOTE]
> You may have to disable SecureBoot when setting up under Custom Mode.
> It depends on your UEFI firmware.


## Configure SecureBoot in UEFI Setup

> [!NOTE]
> It depends on your UEFI firmware.


## Setup under Custom Mode: PK, KEK and DB keys

```bash
sb-keygen.sh
sb-update-key.sh
```

> [!IMPORTANT]
> Make sure your COMPLETELY understand how the commands operate before acting.

Referenced [Simon Ruderich's article](https://ruderich.org/simon/notes/secure-boot-with-grub-and-signed-linux-and-initrd)

### Generate keypairs

```bash
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=PK/"  -keyout PK.key  -out PK.crt  -days 7300 -nodes -sha256
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=KEK/" -keyout KEK.key -out KEK.crt -days 7300 -nodes -sha256
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=db/"  -keyout db.key  -out db.crt  -days 7300 -nodes -sha256
```

### Translate public keys (certificate) to EFI signature lists

```bash
cert-to-efi-sig-list PK.crt PK.esl
sign-efi-sig-list -k PK.key -c PK.crt PK PK.esl PK.auth

cert-to-efi-sig-list KEK.crt KEK.esl
sign-efi-sig-list -k PK.key -c PK.crt KEK KEK.esl KEK.auth

cert-to-efi-sig-list db.crt db.esl
sign-efi-sig-list -k KEK.key -c KEK.crt db db.esl db.auth
```

### Write PK, KEK, DB public keys into EFI Var

```
efi-updatevar -f db.auth db
efi-updatevar -f KEK.auth KEK
efi-updatevar -f PK.auth PK
```

> [!TIP]
> Some UEFI firmwares support enrolling PK, KEK, DB public keys in UEFI Setup interface. It's recommended if your firmware supports.

> [!NOTE]
> The keys can be reset by UEFI Setup. You don't have to back them up.

> [!IMPORTANT]
> Protect your UEFI Setup admin password to keep SecureBoot truly effective.


## Packing unified kernel image with dracut

```bash
dracut-uki-gen.sh [kernel version]
```

**dracut** is a shell script for generating initramfs/initrd image.
The ```.conf``` files are shell scripts with environment variable definitions inside.

Write the kernel cmdline to ```/etc/dracut.conf.d/cmdline.conf```:

```bash
kernel_cmdline=$(cat /proc/cmdline)
```

**Alternatively**, you can also add the kernel cmdline as an option to dracut.

```bash
dracut --kernel-cmdline $(cat /proc/cmdline)
```

For **x86_64** machines:
```bash
dracut \
    --kernel-cmdline $(cat /proc/cmdline) \
    --uefi-stub /lib/systemd/boot/efi/linuxx64.efi.stub \
    --uefi /boot/efi/EFI/$(uname -r).efi
```


## Signing unified kernel image
```bash
$ sb-sign-uki.sh [kernel version]
```

```bash
sbsign --key db.key --cert db.crt --output /boot/efi/EFI/$(uname -r).efi /boot/efi/EFI/$(uname -r).efi
```


## Add boot entry to UEFI for the unified kernel image

```bash
efibootmgr \
    -L "$NAME $VERSION_ID - $(uname -r)" \
    --loader /boot/efi/EFI/$(uname -r).efi \
    --create
```


## Enable SecureBoot in UEFI Setup

Make sure everything is ready.

Reboot and enter UEFI Setup. Enable SecureBoot.


## Check that your SecureBoot settings truly affect

For this step, you have to check manually. It is **IMPORTANT**!

You can add another EFI executable without valid signature to UEFI.
If it **does not** boot, then SecureBoot does work.

> [!TIP]
> Copy /boot except /boot/efi to the encrypted disk. Copy them back when update. So that you don't need to protect /boot anymore.
