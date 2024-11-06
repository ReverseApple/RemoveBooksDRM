#!/bin/zsh

if [[ $(csrutil status) != *"disabled." ]]; then
    echo "SIP must be disabled."
    echo "Consult this documentation for help doing this: https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection#3599244"
    exit 1
fi

if [[ $(defaults read /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation) != "1" ]]; then
    echo "Library validation must be disabled."
    echo "Disable it with: sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true"
    exit 1
fi

function injectDylib {
  SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
	DYLD_INSERT_LIBRARIES="${SCRIPT_DIR}/antidote.dylib" /System/Applications/Books.app/Contents/MacOS/Books
}

injectDylib
