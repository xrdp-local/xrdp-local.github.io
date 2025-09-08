#!/bin/bash

DISTRO_NAME="$1"

DISTRO="${DISTRO_NAME%%-*}"
CODENAME="${DISTRO_NAME#*-}"
ARCHS="$2"
SIGNING_KEY="$3"

case "$DISTRO" in
	debian)
		./build-apt-docker.sh $DISTRO $CODENAME "main" "$ARCHS" "$SIGNING_KEY"
		;;
	ubuntu)
		./build-apt-docker.sh $DISTRO $CODENAME "main" "$ARCHS" "$SIGNING_KEY"
		;;
	fedora)
		./build-rpm-docker.sh $DISTRO $CODENAME "$ARCHS" "$SIGNING_KEY"
		;;
	*)
		echo "Invalid distro $DISTRO." >&2
		exit 1
esac
