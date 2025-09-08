function convert_arch_to_rpm() {
	case $arch in
		amd64)
			echo "x86_64"
			;;
		arm64)
			echo "aarch64"
			;;
		*)
			echo "Invalid arch $arch." >&2
			exit 1
	esac
}
