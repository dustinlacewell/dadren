#!/bin/sh
 
mkdir -p bin
nim c $@ --nimcache=$(pwd)/.nimcache --out:bin/hatchet -p=$(pwd)/../../ hatchet.nim
