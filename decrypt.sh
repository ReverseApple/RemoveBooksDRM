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
	DYLD_INSERT_LIBRARIES=./injected.dylib ~/Desktop/Books.app/Contents/MacOS/Books
}

BOOKS_HOME=~/Library/Containers/com.apple.iBooksX/Data
BOOKS_EPUB_DIR=~/Library/Containers/com.apple.BKAgentService/Data/Documents/iBooks/Books

mkdir $BOOKS_HOME/tmp
mkdir ./decrypted_books

epubFiles=()
itemNames=()

for file in "$BOOKS_EPUB_DIR"/*.epub
do
    itemName=$(xmllint --xpath "/plist/dict/key[text()='itemName']/following-sibling::*[1]/text()" "$file/iTunesMetadata.plist" 2>/dev/null)
    if [[ -z "$itemName" ]]; then
        echo "Failed to extract itemName from $file"
        continue
    fi
    epubFiles+=("$file")
    itemNames+=("$itemName")
done


select bookSel in "${itemNames[@]}";
do
    # Validate the user's input
    if [[ "$REPLY" =~ ^[0-9]+$ ]] && [ "$REPLY" -ge 1 ] && [ "$REPLY" -le ${#itemNames[@]} ]; then

        selected_epub="${epubFiles[REPLY]}"

        open "$BOOKS_HOME/tmp"
        
        cp -R "$selected_epub" "$BOOKS_HOME/tmp"

        sleep 2

        injectDylib

        fileName=$(basename "$selected_epub")
        copiedFilePath="$BOOKS_HOME/tmp/$fileName"
        decryptedEpubPath="${copiedFilePath%.epub}_decrypted.epub"

        mv $decryptedEpubPath ./decrypted_books
        rm -rf "$copiedFilePath"

    else
        echo "Invalid selection. Please select a number from 1 to ${#itemNames[@]}."
    fi
    break
done


