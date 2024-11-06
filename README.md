# RemoveBooksDRM
Apple Books DRM Removal

Currently supports DRM removal of EPUB assets. However, **iBooks assets will be supported in a future release.**

> [!NOTE]
> 
> You need:
> - A computer running macOS.
> 
> You must: 
> - Disable SIP
> - Disable library validation
> - Enable the arm64e ABI boot flag (I think this is only if you are building the project, but I'm not sure)
>
> The CMake build script will check for the arm64e ABI on applicable systems.
> 
> The `inject.sh` script will also provide instructions if any necessary conditions have not been met.

## How to Build
- Run `build.sh`

## How to Use
- Run `inject.sh`
- Apple Books should launch with an alert requesting access to the book container.
If this is not the case, then the payload is likely not injecting properly.
- Further instructions are available in the menu item: `"RemoveBooksDRM" > "Instructions"`

## Legal Use Disclaimer

This software is intended for lawful purposes only, specifically to enable eBook compatibility between different devices.
It is not designed for, nor should it be used for, any form of copyright infringement or illegal activity.

**ReverseApple claims no responsibility for any damage caused by using this software.**
