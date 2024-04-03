# RemoveBooksDRM
Apple Books DRM Removal Proof-of-Concept

## Tested Apple Books Versions
- Version 6.2
  - 6024
  - 6030
- Version 6.3
  - 6040

## How to Build
- Disable SIP
- Enable the arm64e preview ABI in your boot args.
- Run `build.sh`

## How to Use
- build the dylib (see above steps)
- disable library validation...
```sh
sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true
```
- run `decrypt.sh`

## Legal Use Disclaimer

This software is intended for lawful purposes only, specifically to enable eBook compatibility between different devices. It is not designed for, nor should it be used for, any form of copyright infringement or illegal activity.

ReverseApple claims no responsibility for any damage caused by using this software.
