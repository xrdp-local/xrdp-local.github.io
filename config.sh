# Where to place the generated repos in relation to the root of the repository
ROOT_DIR="docs/repos"
# Where ROOT_DIR is served from
REPO_ROOT_URL="https://xrdp-local.github.io/repos"

# Sources to download, GitHub repo names and tags naming versions
SOURCES=(
	shaulk/xrdp_local_deps=v0.10.4.1
	shaulk/xrdp_local=v0.10.4.1
	shaulk/xrdp_local_session=v0.1
)

# Distros to build for
BUILD_DISTROS=(
	ubuntu-jammy
	ubuntu-noble
	ubuntu-plucky
	debian-bookworm
	debian-trixie
	fedora-42
)

# Architectures to build for
BUILD_ARCHS=(
	amd64
)
