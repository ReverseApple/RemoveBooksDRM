arches=("arm64e" "x86_64")

select arch in "${arches[@]}";
do
	# Validate the user's input
    if [[ "$REPLY" =~ ^[0-9]+$ ]] && [ "$REPLY" -ge 0 ] && [ "$REPLY" -le ${#arches[@]} ]; then
    	if [ "$arch" == "arm64e" ]; then
			if [[ $(nvram boot-args) != *"arm64e_preview_abi"* ]]; then
				echo "arm64e preview ABI is not enabled."
				echo "enable it with: sudo nvram boot-args=-arm64e_preview_abi"
				echo "and then restart your mac."
				exit 1
			fi
		fi
		
		clang -dynamiclib -o injected.dylib injected.m -arch "$arch" -framework Foundation
	fi
	break
done
