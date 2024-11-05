cmake_minimum_required(VERSION 3.27)
project(RemoveBooksDRM)

set(CMAKE_CXX_STANDARD 20)
include(FetchContent)

if("${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL "arm64")
    message("Target Architecture: arm64e")
    set(CMAKE_OSX_ARCHITECTURES "arm64e")
elseif("${CMAKE_HOST_SYSTEM_PROCESSOR}" STREQUAL "x86_64")
    message("Target Architecture: x86_64")
else()
    message(FATAL_ERROR "This processor is not supported.")
    return()
endif()


add_library(cure SHARED
        src/main.m
        src/drm.h
        src/drm.m
        src/util.h
)

target_link_libraries(cure PRIVATE "-framework Foundation -framework CoreFoundation -framework Cocoa -framework Security")
