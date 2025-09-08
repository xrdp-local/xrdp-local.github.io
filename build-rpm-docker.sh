#!/bin/bash

set -e

source util.sh
source config.sh

DISTRO="$1"
VERSION="$2"
ARCHS="$3"
SIGNING_KEY="$4"

declare -a archs_rpm=()

for arch in $ARCHS
do
	archs_rpm+=("$(convert_arch_to_rpm "$arch")")
done


docker buildx build \
	--platform linux/amd64 \
	-t repo_builder_rpm \
	-f Dockerfile_rpm \
	--load \
	.

docker run \
	--rm \
	-i \
	-v $PWD:/src \
	-v $PWD/$ROOT_DIR:/output \
	repo_builder_rpm \
		/src/build-rpm.sh \
		"$DISTRO" \
		"$VERSION" \
		"${archs_rpm[*]}" \
		"$SIGNING_KEY"
