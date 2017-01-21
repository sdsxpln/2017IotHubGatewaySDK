#!/bin/bash
# Copyright (c) Microsoft. All rights reserved.
# Licensed under the MIT license. See LICENSE file in the project root for full license information.

set -e

build_root=$(cd "$(dirname "$0")/.." && pwd)
build_root=$build_root/build_nodejs

# clear the Node.js build folder so we have a fresh build
rm -rf $build_root
mkdir -p $build_root

# build Node.js
pushd $build_root
git clone -b shared-691 --depth 1 https://github.com/avranju/node.git
pushd node
./configure --shared
make -j $(nproc)
popd

# create a 'dist' folder where the includes/libs live
mkdir -p $build_root/dist/inc/libplatform

# copy the include files
cp $build_root/node/src/env.h $build_root/dist/inc
cp $build_root/node/src/env-inl.h $build_root/dist/inc
cp $build_root/node/src/node.h $build_root/dist/inc
cp $build_root/node/src/node_version.h $build_root/dist/inc
cp $build_root/node/deps/uv/include/*.h $build_root/dist/inc
cp $build_root/node/deps/v8/include/*.h $build_root/dist/inc
cp $build_root/node/deps/v8/include/libplatform/*.h $build_root/dist/inc/libplatform

# copy the library files
mkdir -p $build_root/dist/lib
find $build_root | grep "\\.a$" | xargs -I {file} cp {file} $build_root/dist/lib

# copy libnode.so.XX
cp $build_root/node/out/Release/lib.target/libnode.so.* $build_root/dist/lib

# make a symlink called libnode.so that points to this file
ln -s $build_root/dist/lib/libnode.so.$(ls $build_root/dist/lib/libnode.so.* | cut -d . -f 3) $build_root/dist/lib/libnode.so

# export environment variables for where the include/lib files can be found
echo
echo Node JS has been built and the includes and library files are in:
echo
echo "    $build_root/dist"
echo
echo Export the following variables so that the Azure IoT Gateway SDK build scripts can find these files.
echo
echo "    export NODE_INCLUDE=\"$build_root/dist/inc\""
echo "    export NODE_LIB=\"$build_root/dist/lib\""
echo

