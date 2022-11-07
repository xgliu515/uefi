#!/bin/bash
# Copyright (c) 2015 by Roderick W. Smith
# Licensed under the terms of the GPL v3

echo -n "Enter a Common Name to embed in the keys: "
read NAME

for n in PK KEK db shim
do
  openssl genrsa -out "$n.key" 2048
  openssl req -new -x509 -sha256 -subj "/CN=$NAME UEFI $n 2022/" -key "$n.key" -out "$n.pem" -days 3650
  openssl x509 -in "$n.pem" -inform PEM -out "$n.der" -outform DER
done


GUID=`python3 -c 'import uuid; print(str(uuid.uuid1()))'`
echo $GUID > GUID.txt

for n in PK KEK db
do
  sbsiglist --owner "$GUID" --type x509 --output "$n.esl" "$n.der"
done

for n in PK=PK KEK=PK db=KEK
do
  sbvarsign --key "${n#*=}.key" --cert "${n#*=}.pem"  --output "${n%=*}.auth" "${n%=*}" "${n%=*}.esl"
done

chmod 0600 *.key

echo ""
echo ""
echo "For use with KeyTool, copy the *.auth and *.esl files to a FAT USB"
echo "flash drive or to your EFI System Partition (ESP)."
echo "For use with most UEFIs' built-in key managers, copy the *.cer files;"
echo "but some UEFIs require the *.auth files."
echo ""


# sign-efi-sig-list
# cert-to-efi-sig-list
# hash-to-efi-sig-list
