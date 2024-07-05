#!/bin/sh

ECALROOT="$HOME/ecal"
mkdir -p "${ECALROOT}/keyring/private-keys-v1.d"
chmod -R 700 "${ECALROOT}/keyring/"
GPGARGS="--homedir=${ECALROOT}/keyring --no-default-keyring --keyring ${ECALROOT}/keyring/trust.db --pinentry-mode=loopback --passphrase-file ${ECALROOT}/keyring/.pass"

gpg ${GPGARGS} --import ${ECALROOT}/keyring/public.key ${ECALROOT}/keyring/private.key 
