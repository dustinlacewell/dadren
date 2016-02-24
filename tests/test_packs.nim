#
# tests
#

include ../dadren/packs.nim

import unittest
from sequtils import toSeq
from algorithm import sorted
from os import `/`, createDir, removeDir

suite "loadPack":
  setup:
    let
      temp_dir = "tmp"
      root_filename = temp_dir / "root.json"
      include_filename = temp_dir / "include.json"
      recursive_filename = temp_dir / "rescursive.json"

    let root_pack = %*
      {
        "includes": [ include_filename ],
        "assets": {
          "new": "NEW",
          "bar": "BAR!"
        }
      }

    let include_pack = %*
      {
        "assets": {
          "foo": "FOO",
          "bar": "BAR"
        }
      }

    let recursive_pack = %*
      {
        "includes": [ recursive_filename ],
        "assets": {
          "foo": "FOO",
          "bar": "BAR"
        }
      }

    createDir(temp_dir)
    writeFile(root_filename, $(root_pack))
    writeFile(include_filename, $(include_pack))
    writeFile(recursive_filename, $(recursive_pack))
    let pack = loadPack(root_filename)

  teardown:
    removeDir(temp_dir)

  test "normal includes":
    let
      foo = pack["foo"].getStr
      bar = pack["bar"].getStr
      new = pack["new"].getStr

    check(foo == "FOO")
    check(bar == "BAR!")
    check(new == "NEW")

  test "recursive includes":
    expect ValueError:
      let recurse = loadPack(recursive_filename)
