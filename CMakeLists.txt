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


# Prepare SSZipArchive
FetchContent_Declare(
        SSZipArchive
        GIT_REPOSITORY https://github.com/ZipArchive/ZipArchive.git
        GIT_TAG v2.4.2
)
FetchContent_MakeAvailable(SSZipArchive)

# Fetch zlib (SSZipArchive's dependency)
FetchContent_Declare(
        zlib
        GIT_REPOSITORY https://github.com/madler/zlib.git
        GIT_TAG        v1.2.11  # You can specify the version you need
)

FetchContent_MakeAvailable(zlib)

file(GLOB_RECURSE SSZIPARCHIVE_SOURCES
        ${ssziparchive_SOURCE_DIR}/SSZipArchive/*.h
        ${ssziparchive_SOURCE_DIR}/SSZipArchive/*.m
        ${ssziparchive_SOURCE_DIR}/SSZipArchive/*.c
)

add_library(cure SHARED
        src/main.m
        src/drm.h
        src/drm.m
#        src/rdrm.h
#        src/rdrm.m
        src/util.h
)

# Define the HAVE_WZAES macro to stop giving an undefined symbol error from SSZipArchive
target_compile_definitions(cure PRIVATE HAVE_WZAES)
target_include_directories(cure PUBLIC ${ssziparchive_SOURCE_DIR})
target_sources(cure PRIVATE ${SSZIPARCHIVE_SOURCES})

target_link_libraries(cure PRIVATE zlibstatic)
target_link_libraries(cure PRIVATE "-framework Foundation -framework CoreFoundation -framework Cocoa -framework Security")
