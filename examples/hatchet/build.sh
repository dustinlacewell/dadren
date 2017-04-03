#!/bin/sh

mkdir -p bin
nim c $@ --nimcache=$(pwd)/.nimcache --debugger:native --out:bin/hatchet hatchet.nim
