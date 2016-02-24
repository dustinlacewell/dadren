import unittest

include ../dadren/textures

suite "textures.nim":
  setup:
    let
      tm = newTextureManager(nil, nil)
      temp_dir = "tmp"
      root_filename = temp_dir / "textures.json"
      incomplete_filename = temp_dir / "incomplete_textures.json"

    let texture_pack = %*
      {
        "assets": {
          "example_texture": {
            "filename": "textures/example_texture.png",
            "description": "A texture used as an example",
            "authors": ["foo", "bar"]
          }
        }
      }

    let incomplete_pack = %*
      {
        "assets": {
          "example_texture": {
            "description": "A texture used as an example",
            "authors": ["foo", "bar"]
          }
        }
      }

    createDir(temp_dir)
    writeFile(root_filename, $(texture_pack))
    writeFile(incomplete_filename, $(incomplete_pack))

  teardown:
    removeDir(temp_dir)

  test "texture packs":
    expect Exception:
      tm.loadPack(root_filename)

  test "requires filename":
    expect NoSuchResourceError:
      tm.loadPack(incomplete_filename)
