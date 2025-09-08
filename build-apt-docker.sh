#!/bin/bash

set -e

source config.sh

DISTRO="$1"
CODENAME="$2"
SECTION="$3"
ARCHS="$4"
SIGNING_KEY="$5"


docker buildx build \
	--platform linux/amd64 \
	-t repo_builder_apt \
	-f Dockerfile_apt \
	--load \
	.

docker run \
	--rm \
	-i \
	-v $PWD:/src \
	-v $PWD/$ROOT_DIR:/output \
	repo_builder_apt \
		/src/build-apt.sh \
		"$DISTRO" \
		"$CODENAME" \
		"$SECTION" \
		"$ARCHS" \
		"$SIGNING_KEY"
