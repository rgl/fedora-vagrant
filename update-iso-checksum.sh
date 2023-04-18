#!/bin/bash
# this will update the fedora.json file with the current netboot image checksum.
# see https://fedoraproject.org/security/
set -euxo pipefail
wget -qO- https://fedoraproject.org/fedora.gpg | gpg --import
version="$(jq -r '.variables.iso_url' fedora.json | perl -ne '/-(\d+.+)\.iso$/ && print $1')"
iso_url="$(jq -r '.variables.iso_url' fedora.json)"
iso_checksum_url="$(dirname $iso_url)/Fedora-Server-$version-x86_64-CHECKSUM"
iso_checksum_file=$(basename $iso_checksum_url)
curl -O -L --silent --show-error $iso_checksum_url
gpg --verify $iso_checksum_file
iso_checksum=$(grep -E "SHA256.+$(basename $iso_url)" $iso_checksum_file | awk '{print $4}')
sed -i -E "s,(\"iso_checksum\": \").*(\"),\\1sha256:$iso_checksum\\2,g" fedora.json
rm $iso_checksum_file
echo 'iso_checksum updated successfully'
