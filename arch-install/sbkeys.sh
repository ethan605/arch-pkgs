#! /usr/bin/env bash

uuidgen --random > GUID.txt
GUID=$(cat GUID.txt)
CN_PREFIX="Arch"

# PK - Platform Key
openssl req -newkey rsa:4096 -nodes -keyout PK.key -new -x509 -sha256 -days 3650 -subj "/CN=$CN_PREFIX Platform Key/" -out PK.crt
openssl x509 -outform DER -in PK.crt -out PK.cer
cert-to-efi-sig-list -g "$GUID" PK.crt PK.esl
sign-efi-sig-list -g "$GUID" -k PK.key -c PK.crt PK PK.esl PK.auth

# Sign an empty file to allow removing Platform Key when in "User Mode"
sign-efi-sig-list -g "$GUID" -c PK.crt -k PK.key PK /dev/null rm_PK.auth

# KEK - Key Exchange Key
openssl req -newkey rsa:4096 -nodes -keyout KEK.key -new -x509 -sha256 -days 3650 -subj "/CN=$CN_PREFIX Key Exchange Key/" -out KEK.crt
openssl x509 -outform DER -in KEK.crt -out KEK.cer
cert-to-efi-sig-list -g "$(< GUID.txt)" KEK.crt KEK.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt KEK KEK.esl KEK.auth

# db - Signature Database Key
openssl req -newkey rsa:4096 -nodes -keyout db.key -new -x509 -sha256 -days 3650 -subj "/CN=$CN_PREFIX Signature Database key/" -out db.crt
openssl x509 -outform DER -in db.crt -out db.cer
cert-to-efi-sig-list -g "$GUID" db.crt db.esl
sign-efi-sig-list -g "$GUID" -k KEK.key -c KEK.crt db db.esl db.auth

chmod 0600 *.key