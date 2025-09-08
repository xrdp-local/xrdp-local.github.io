#!/bin/bash

source util.sh
source config.sh

declare -a git_api_infos=()

function get_git_api_info() {
	for tag in ${SOURCES[@]}
	do
		repo_name="${tag%%=*}"
		repo_tag="${tag#*=}"
		git_api_infos+=("$(curl "https://api.github.com/repos/$repo_name/releases/tags/$repo_tag")")
	done
}

function generate_hash_file() {
	rm -f sha256sums
	for git_api_info in "${git_api_infos[@]}"
	do
		git_hash_types="$(echo "$git_api_info" | jq -r '.assets[] | (.digest | split(":")[0])' | sort -u)"
		if [ "$git_hash_types" != "sha256" ]
		then
			echo "Invalid hash type $git_hash_types." >&2
			exit 1
		fi
		echo "$git_api_info" | jq -r '.assets[] | (.digest | split(":")[1]) + " *" + .name' >>sha256sums
	done
}

# download_packages type distro version
function download_packages() {
	for arch in "${BUILD_ARCHS[@]}"
	do
		case "$1" in
			apt)
				path="$ROOT_DIR/apt/pool/$3"
				version_suffix="$2-$3"
				noarch=_all.
				;;
			rpm)
				arch=$(convert_arch_to_rpm "$arch")
				case "$2" in
					fedora)
						version_suffix="fc$3"
						;;
					*)
						echo "Invalid distro $2." >&2
						exit 1
				esac
				path="$ROOT_DIR/rpm/$2/$3/$arch"
				noarch=.noarch.
				;;
			*)
				echo "Invalid type $1." >&2
				exit 1
		esac

		mkdir -p "$path"

		for git_api_info in "${git_api_infos[@]}"
		do
			for url in $(echo "$git_api_info" | jq -r '.assets[] | .browser_download_url' | fgrep -e "$arch" -e "$noarch" | fgrep "$version_suffix")
			do
				# Download the package
				curl -s -L -o "$path/$(basename "$url")" "$url"

				# Verify the package sha256sum
				grep "$(basename "$url")" sha256sums | sed -r "s# \\*# *$path/#" | sha256sum -c

				# apt-ftparchive requires the package name to be canonical,
				# rename it to its original name from dpkg-buildpackage
				if [ "$1" == "apt" ]
				then
					new_name="$(basename "$url" | sed -r "s#\\.$version_suffix##")"
					mv -v "$path/$(basename "$url")" "$path/$new_name"
				fi
			done
		done
	done
}

get_git_api_info
generate_hash_file

for distro in ${BUILD_DISTROS[@]}
do
	distro_name="${distro%%-*}"
	distro_version="${distro#*-}"
	case "$distro_name" in
		debian)
			download_packages "apt" "$distro_name" "$distro_version"
			;;
		ubuntu)
			download_packages "apt" "$distro_name" "$distro_version"
			;;
		fedora)
			download_packages "rpm" "$distro_name" "$distro_version"
			;;
		*)
			echo "Invalid distro $distro_name." >&2
			exit 1
	esac
done
