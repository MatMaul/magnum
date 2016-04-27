#!/bin/bash

cd /etc/pki/ca-trust/source/anchors/

BASE_URL=https://cafiles.cern.ch/cafiles/certificates/
CERTS=( "CERN Root Certification Authority 2" "CERN Grid Certification Authority" "CERN Certification Authority" )

for CERT in "${CERTS[@]}"
do
  URL="$BASE_URL$CERT.crt"
  curl "$( echo "$URL" | sed 's/ /%20/g' )" -o "$CERT.crt"
  FIRST_LINE=$(head -1 "$CERT.crt")
  if [[ ! $FIRST_LINE == *"BEGIN CERTIFICATE"* ]]; then
    openssl x509 -inform DER -in "$CERT.crt" -out "$CERT.pem"
    rm "$CERT.crt"
  else
    mv "$CERT.crt" "$CERT.pem"
  fi
done

update-ca-trust

