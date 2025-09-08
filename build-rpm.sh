#!/bin/bash

set -e

DISTRO="$1"
VERSION="$2"
ARCHS="$3"
SIGNING_KEY="$4"

source /src/config.sh

export GPG_TTY=/dev/null

echo "$SIGNING_KEY" | gpg --import -
cat > ~/.rpmmacros <<EOF
%_signature gpg
%_gpg_name $(gpg --list-keys --with-colons | grep '^uid:' | cut -d: -f10)
%_gpgbin /usr/bin/gpg2
EOF

cd "/output/rpm/$DISTRO/$VERSION"

for arch in $ARCHS
do
	cd $arch
	for rpm in *.rpm
	do
		rpm --addsign "$rpm"
	done
	createrepo .
	gpg --detach-sign --armor --yes "repodata/repomd.xml"
	cd ..
done

cd /output
gpg --export --armor > GPG-KEY-xrdp-local
cat >$DISTRO-$VERSION.repo <<EOF
# Put this file at /etc/yum.repos.d/xrdp-local.repo
# and the GPG key at /etc/pki/rpm-gpg/GPG-KEY-xrdp-local

[xrdp-local]
name=xrdp-local
baseurl=$REPO_ROOT_URL/rpm/$DISTRO/$VERSION/\$basearch
enabled=1
gpgcheck=1
gpgkey=/etc/pki/rpm-gpg/GPG-KEY-xrdp-local
EOF
