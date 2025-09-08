#!/bin/bash

set -e

DISTRO="$1"
CODENAME="$2"
SECTION="$3"
ARCHS="$4"
SIGNING_KEY="$5"

source /src/config.sh

cat >/tmp/apt-ftparchive.conf <<-EOF
	Dir {
	  ArchiveDir ".";
	};

	Default {
	  Packages::Compress ". gzip xz";
	  Contents::Compress ". gzip xz";
	  Packages::Extensions ".deb .ddeb";
	};

	TreeDefault {
	  BinCacheDB "/tmp/packages.db";
	};

	Tree "dists/$CODENAME" {
		Architectures "$ARCHS";
		Sections "$SECTION";
	    FileList "/tmp/files-\$(ARCH)";
	};
EOF

cat >/tmp/apt-release.conf <<-EOF
	APT::FTPArchive::Release {
	  Label "${DISTRO^}";
	  Suite "$CODENAME";
	  Codename "$CODENAME";
	  Architectures "$ARCHS";
	  Components "$SECTION";
	};
EOF

cd /output/apt

for arch in $ARCHS
do
	mkdir -p dists/$CODENAME/$SECTION/binary-$arch
	find pool/$CODENAME -type f -name "*$arch.*deb" -or -name "*all.deb" | sort > /tmp/files-$arch
done

apt-ftparchive -c=/tmp/apt-ftparchive.conf generate /tmp/apt-ftparchive.conf

apt-ftparchive -c=/tmp/apt-release.conf release "dists/$CODENAME" >"dists/$CODENAME/Release"

echo "$SIGNING_KEY" | gpg --no-default-keyring --keyring /tmp/apt.keyring --import -
gpg --no-default-keyring --keyring /tmp/apt.keyring -abs --yes -o "dists/$CODENAME/Release.gpg" "dists/$CODENAME/Release"
gpg --no-default-keyring --keyring /tmp/apt.keyring --clearsign --yes -o "dists/$CODENAME/InRelease" "dists/$CODENAME/Release"

cd ..
cat >$DISTRO-$CODENAME.sources <<EOF
# Put this file at /etc/apt/sources.list.d/xrdp-local.sources

Types: deb
URIs: $REPO_ROOT_URL/apt
Suites: $CODENAME
Components: $SECTION
Signed-By: |
$(gpg --no-default-keyring --keyring /tmp/apt.keyring --export --armor | sed 's/^/    /')
EOF
