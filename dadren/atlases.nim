## Overview
## ========
## An **Atlas**, like a Texture, represents raw image data in GPU memory. However, an Atlas also has an associated two-dimensional "partition size" which must evenly partition the underlying texture. Instead of blitting the entire texture, specific sub-regions can be draw by referencing them by a numerical index. The indexes are assigned left-to-right and top-to-bottom:

## **Example sub-region layouts**
##
## .. code-block:: nimrod
##     +---+---+---+      +---+---+
##     |   |   |   |      |   |   |
##     | 0 | 1 | 2 |      | 0 | 1 |
##     |   |   |   |      |   |   |
##     +-----------+      +-------+     +---+---+---+---+---+---+
##     |   |   |   |      |   |   |     |   |   |   |   |   |   |
##     | 3 | 4 | 5 |      | 2 | 3 |     | 0 | 1 | 2 | 3 | 4 | 5 |
##     |   |   |   |      |   |   |     |   |   |   |   |   |   |
##     +---+---+---+      +-------+     +---+---+---+---+---+---+
##                        |   |   |
##                        | 4 | 5 |
##                        |   |   |
##                        +---+---+
##


import json
import marshal
import os
import strutils
import tables

from sdl2 import WindowPtr, RendererPtr

from ./packs import loadPack
from ./textures import Texture, TextureManager, newTextureManager, load, render
from ./exceptions import InvalidResourceError, NoSuchResourceError
from ./utils import Size

type
  AtlasInfo* = object
    ## Meta-data describing an Atlas
    filename*: string ## filename used to load the Atlas
    width*: int ## the width of the Atlas partition
    height*: int ## the height of the Atlas partition
    name*: string ## name of the Atlas in an AtlasManager
    description*: string ## description of the Atlas
    authors*: seq[string] ## authors of the Atlas

  Atlas* = ref object
    ## Used for rendering sub-regions of a Texture
    info*: AtlasInfo ## meta-data describing the Atlas
    width: int ## Atlas width in sub-regions
    height: int ## Atlas height in sub-regions
    texture*: Texture ## Texture underlying the Atlas

  AtlasManager* = ref object
    ## Used for loading and managing Atlases
    textures: TextureManager ## textures backing managed Atlases
    registry: Table[string, Atlas] ## loaded Atlases by name

proc newAtlasManager*(window: WindowPtr, display: RendererPtr): AtlasManager =
  new(result)
  result.textures = newTextureManager(window, display)
  result.registry = initTable[string, Atlas]()

proc validateTileSize(texture: Texture, width, height: int) =
  # ensure the tile_size evenly divides into the Texture
  if (texture.size.w %% width != 0 or
      texture.size.h %% height != 0):
    let msg = "Atlas partition dimensions are incompatible with texture `$1`."
    raise newException(InvalidResourceError, msg.format(texture.info.filename))

proc load*(am: AtlasManager,
           name, filename: string,
           width, height: int,
           description: string = nil,
           authors: seq[string] = nil): Atlas =
  ## Load an image resource from disk partitioned into sub-regions of t_width and
  ## t_height. Once loaded sub-regions may be rendered by index. The Atlas can be
  ## retrieved from the AtlasManager using the provided name.
  if am.registry.hasKey(name):
    return am.registry[name]

  let
    texture = am.textures.load(name, filename)
    info = AtlasInfo(filename:filename, name:name,
                     width:width, height:height,
                     description:description,
                     authors: authors)

  texture.validateTileSize(width, height)
  result = Atlas(info:info, texture:texture)
  am.registry[name] = result

proc loadPack*(am: AtlasManager, filename: string) =
  ## Load a resource-pack of Altases. Assets inside of an Atlas resource-pack should
  ## be unmarshalable by the **AtlasAsset** type.
  ##
  ## **Example AtlasAsset JSON**
  ##
  ## .. code-block:: nimrod
  ##    "example_atlas_asset": {
  ##      "filename": "atlases/example_atlas.png",
  ##      "width": 32, "height": 32
  ##    }

  let pack = loadPack(filename)
  for name, asset_data in pack:
    let info = to[AtlasInfo]($asset_data)
    discard am.load(name, info.filename,
                    info.width, info.height,
                    info.description, info.authors)

proc get*(am: AtlasManager, name: string): Atlas =
  ## Get a loaded Atlas by name
  if not am.registry.hasKey(name):
    let msg = "No atlas with name `" & name & "` is loaded."
    raise newException(NoSuchResourceError, msg)
  am.registry[name]

proc calculateAtlasSize(texture: Texture, width, height: int): Size =
  result.w = texture.size.w /% width
  result.h = texture.size.h /% height

proc calculateRegionPosition*(atlas: Atlas, n): tuple[x, y: int] =
  ## Return the pixel position of indexed sub-region `n`
  let atlas_size = calculateAtlasSize(atlas.texture,
                                      atlas.info.width,
                                      atlas.info.height)
  ((if n > 0: n %% atlas_size.w else: 0),
   (if n > 0: n /% atlas_size.h else: 0))

proc render*(display: RendererPtr, atlas: Atlas, tx, ty, dx, dy: int) =
  ## Render the sub-region tx, ty of atlas to the destination dx, dy of display
  let
    sx = tx *% atlas.info.width
    sy = ty *% atlas.info.height

  display.render(atlas.texture, sx, sy, dx, dy,
                 atlas.info.width,
                 atlas.info.height)

proc render*(display: RendererPtr, atlas: Atlas, n, dx, dy: int) =
  ## Render the indexed sub-region n of atlas to the destination dx, dy of display
  let (tx, ty) = atlas.calculateRegionPosition(n)
  display.render(atlas, tx, ty, dx, dy)
