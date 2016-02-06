#!/bin/sh

nim c $@ --nimcache=$(pwd)/.nimcache -p=$(pwd)/../../ hatchet.nim
