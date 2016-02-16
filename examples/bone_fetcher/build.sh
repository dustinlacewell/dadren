#!/bin/sh
 
mkdir -p bin
nim c $@ --nimcache=$(pwd)/.nimcache --out:bin/bone_fetcher -p=$(pwd)/../../ bone_fetcher.nim
