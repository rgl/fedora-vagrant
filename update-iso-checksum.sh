#!/bin/bash
# this will update the fedora.json file with the current netboot image checksum.
# see https://fedoraproject.org/security/
set -euxo pipefail
wget -qO- https://fedoraproject.org/fedora.gpg | gpg --import
# e.g. https://download.fedoraproject.org/pub/fedora/linux/releases/test/45_Beta/Server/x86_64/iso/Fedora-Server-netinst-x86_64-45_Beta-1.3.iso
# e.g. https://download.fedoraproject.org/pub/fedora/linux/releases/test/45_Beta/Server/x86_64/iso/Fedora-Server-iso-45_Beta-1.3-x86_64-CHECKSUM
iso_url="$(perl -ne '/default\s*=\s*\"(https:.+\.fedoraproject\.org.+)\"/ && print $1' <fedora.pkr.hcl)"
version="$(echo "$iso_url" | perl -ne '/-(\d+_[A-Za-z0]+-\d+(\.\d+)+)\.iso$/ && print $1')"
iso_checksum_url="$(dirname $iso_url)/Fedora-Server-iso-$version-x86_64-CHECKSUM"
iso_checksum_file=$(basename $iso_checksum_url)
curl -O -L --silent --show-error $iso_checksum_url
gpg --verify $iso_checksum_file
iso_checksum=$(grep -E "SHA256.+$(basename $iso_url)" $iso_checksum_file | awk '{print $4}')
for f in fedora*.pkr.hcl; do
    sed -i -E "s,(default\s*=\s*\")(sha256:[a-z0-9]+|none)(\"),\\1sha256:$iso_checksum\\3,g" $f
done
rm $iso_checksum_file
echo 'iso_checksum updated successfully'
