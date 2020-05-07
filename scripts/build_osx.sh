#!/bin/bash

rm -rf build
mkdir build
cp -r assets build/assets
cd build

odin build ../src -out=$1
