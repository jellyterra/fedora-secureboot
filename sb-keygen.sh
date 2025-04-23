#!/bin/bash

set -e

function KEYGEN {
    openssl req -new -x509 -newkey rsa:2048 -sha256 -nodes -days 7300 -subj "/CN=$1/" -keyout $1.key -out $1.crt
}

KEYGEN PK
KEYGEN KEK
KEYGEN db

cert-to-efi-sig-list PK.crt PK.esl
cert-to-efi-sig-list KEK.crt KEK.esl
cert-to-efi-sig-list db.crt db.esl

sign-efi-sig-list -k PK.key -c PK.crt PK PK.esl PK.auth
sign-efi-sig-list -k PK.key -c PK.crt KEK KEK.esl KEK.auth
sign-efi-sig-list -k KEK.key -c KEK.crt db db.esl db.auth
