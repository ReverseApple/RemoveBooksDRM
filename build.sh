if [[ $(nvram boot-args) != *"arm64e_preview_abi"* ]]; then
	echo "arm64e preview ABI is not enabled."
	echo "enable it with: sudo nvram boot-args=-arm64e_preview_abi"
	echo "and then restart your mac."
	exit 1
fi

clang -dynamiclib -o injected.dylib injected.m -arch arm64e -framework Foundation