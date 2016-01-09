#!/bin/sh

nim c -r --nimcache=$(pwd)/.nimcache -o=$(pwd)/dadren $(pwd)/src/dadren.nim
