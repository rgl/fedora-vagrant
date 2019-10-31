#!/bin/bash
# this will update the fedora.json file with the current netboot image checksum.
# see https://getfedora.org/keys/
set -eux
version=31-1.9
gpg --keyserver hkp://keys.fedoraproject.org --recv-keys 0x3C3359C4
iso_url=$(jq -r '.variables.iso_url' fedora.json)
iso_checksum_url="$(dirname $iso_url)/Fedora-Server-$version-x86_64-CHECKSUM"
iso_checksum_file=$(basename $iso_checksum_url)
curl -O -L --silent --show-error $iso_checksum_url
gpg --verify $iso_checksum_file
iso_checksum=$(grep -E "SHA256.+$(basename $iso_url)" $iso_checksum_file | awk '{print $4}')
sed -i -E "s,(\"iso_checksum\": \")([a-f0-9]*)(\"),\\1$iso_checksum\\3,g" fedora.json
rm $iso_checksum_file
echo 'iso_checksum updated successfully'
