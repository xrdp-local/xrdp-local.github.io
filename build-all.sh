#!/bin/bash

set -e

source config.sh


if [ "$SIGNING_KEY" == "" ]
then
	if [ "$1" == "" ]; then
		echo "Signing key not provided." >&2
		exit 1
	fi
	SIGNING_KEY="$1"
fi

mkdir -p "$ROOT_DIR"

./download-packages.sh

for distro in ${BUILD_DISTROS[@]}
do
	echo "Building $distro..." >&2
	./build.sh "$distro" "${BUILD_ARCHS[*]}" "$SIGNING_KEY"
done

docker buildx build \
	-t repo_builder_python \
	-f Dockerfile_python \
	--load \
	.

docker run \
	--rm \
	-i \
	-v $PWD:/src \
	repo_builder_python \
		bash -c "
			cd /src &&
			python generate_index.py '$ROOT_DIR' '$ROOT_DIR/index.html'
		"


git add "$ROOT_DIR"
git commit -m "Update repos from $(git rev-parse HEAD)"
