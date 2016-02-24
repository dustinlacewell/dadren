## Overview
## ========
## A **Tileset** acts as a single registry for accessing tiles by name across two or more NamedAtlases. All included NamedAtlases must have the same partition dimensions. As they are loaded, tiles will overwrite any existing tiles with the same name.

import os
import tables
import marshal
import json
import strutils

import sdl2

import ./exceptions
import ./namedatlases
import ./packs
import ./utils

type
  AtlasTable = Table[string, NamedAtlas]

  TilesetAtlasInfo* = object
    ## Used for deserializing a single Tileset Atlas from resource-packs
    filename*: string ## path on disk of source image
    tiles*: seq[string] ## a list of tile names

  TilesetInfo = object
    ## Used for deserializing TilesetAssets from resource-packs
    width*: int ## width of tiles
    height*: int ## height of tiles
    atlases*: seq[TilesetAtlasInfo] ## all included TilesetAtlasAssets
    name*: string ## name of the Atlas in an AtlasManager
    description*: string ## description of the Atlas
    authors*: seq[string] ## authors of the Atlas

  Tileset* = ref object
    info*: TilesetInfo
    atlases*: seq[NamedAtlas]

  TilesetManager* = ref object
    atlases*: NamedAtlasManager
    registry*: Table[string, Tileset]

proc newTilesetManager*(window: WindowPtr, display:RendererPtr): TilesetManager =
  new(result)
  result.atlases = newNamedAtlasManager(window, display)
  result.registry = initTable[string, Tileset]()

proc loadPack*(tm: TilesetManager, filename: string) =
  ## Load a resource-pack of Tilesets. Assets inside of a Tilesets resource-pack
  ## should be unmarshalable by the **TilesetInfo** type.
  ##
  ## **Example TilesetInfo JSON**
  ##
  ## .. code-block:: nimrod
  ##    "example_tileset": {
  ##      "description": "A texture used as an example",
  ##      "authors": ["foo", "bar"]
  ##      "width": 32, "height": 32,
  ##      "atlases": [
  ##        {
  ##          "filename": "tilesets/terrain.png",
  ##          "tiles": ["dirt", "stone", "water", "ice"]
  ##        },
  ##        {
  ##          "filename": "tilesets/plants.png",
  ##          "tiles": ["bush", "grass", "tree", "cat-tail"]
  ##        }
  ##    }
  let pack = loadPack(filename)
  for name, asset_data in pack:
    let info = to[TilesetInfo]($asset_data)
    var atlases = newSeq[NamedAtlas]()
    for atlas_info in info.atlases:
      let new_atlas = tm.atlases.load(name, atlas_info.filename,
                                      info.width, info.height,
                                      atlas_info.tiles,
                                      info.description, info.authors)
      atlases.add(new_atlas)
    tm.registry[name] = Tileset(info:info, atlases:atlases)

proc get*(tm: TilesetManager, name): Tileset =
  if not tm.registry.hasKey(name):
    let msg = "No Tileset with name `$1` is loaded."
    raise newException(NoSuchResourceError, msg.format(name))
  tm.registry[name]

proc render*(display: RendererPtr, tileset: Tileset, name: string, dx, dy: int) =
  for atlas in tileset.atlases:
    if name in atlas.info.names:
      display.render(atlas, name, dx, dy)
      return


