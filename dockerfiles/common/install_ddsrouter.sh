#!/usr/bin/env bash
set -euo pipefail

prefix="${DDS_ROUTER_PREFIX:-/opt/ddsrouter}"
build_root="${DDS_ROUTER_BUILD_DIR:-/tmp/ddsrouter-build}"
mkdir -p "$build_root/src"

while read -r repository version; do
    git clone --depth 1 --branch "$version" "https://github.com/eProsima/$repository.git" "$build_root/src/$repository"
done <<'SOURCES'
foonathan_memory_vendor v1.4.1
Fast-CDR v2.3.7
Fast-DDS v3.4.3
dev-utils v1.5.4
DDS-Pipe v1.5.4
DDS-Router v3.5.4
SOURCES

for package in foonathan_memory_vendor Fast-CDR Fast-DDS \
    dev-utils/cmake_utils dev-utils/cpp_utils \
    DDS-Pipe/ddspipe_core DDS-Pipe/ddspipe_participants DDS-Pipe/ddspipe_yaml \
    DDS-Router/ddsrouter_core DDS-Router/ddsrouter_yaml DDS-Router/tools/ddsrouter_tool; do
    cmake -S "$build_root/src/$package" -B "$build_root/build/$package" \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" \
        -DCMAKE_PREFIX_PATH="$prefix" -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_INSTALL_RPATH="$prefix/lib" \
        -DBUILD_TESTING=OFF -DBUILD_TESTS=OFF -DCOMPILE_EXAMPLES=OFF \
        -DSECURITY=OFF -DSQLITE3_SUPPORT=OFF
    cmake --build "$build_root/build/$package" --parallel "${DDS_ROUTER_BUILD_JOBS:-2}"
    cmake --install "$build_root/build/$package"
done

# Keep these private libraries out of the ROS middleware search path.
"$prefix/bin/ddsrouter" --version
