cmake_minimum_required(VERSION 3.27)
project(RemoveBooksDRM)

set(CMAKE_CXX_STANDARD 20)

if("${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL "arm64")
    message("Target Architecture: arm64e")
    set(CMAKE_OSX_ARCHITECTURES "arm64e")
elseif("${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL "x86_64")
    message("Target Architecture: x86_64")
else()
    message("Error: this processor is not supported.")
    return()
endif()

add_library(cure SHARED src/main.mm src/util.h src/util.m)
target_link_libraries(cure "-framework Foundation -framework CoreFoundation -framework Cocoa")
