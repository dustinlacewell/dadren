## Overview
## ========
## A **NamedAtlas**, like an Atlas and Texture, represents raw image data in GPU memory. Like an Atlas, it too provides an even partitioning of the underlying Texture. The NamedAtlas, however, also provides a string-based name for each indexed sub-region allowing for a more semantic interface.

import tables
import strutils
import json
import marshal

from sdl2 import WindowPtr, RendererPtr

from ./packs import loadPack
from ./atlases import Atlas, AtlasManager, AtlasInfo
from ./atlases import newAtlasManager, calculateRegionPosition, load, render
from ./exceptions import NoSuchResourceError
from ./utils import Size

type

  NamedAtlasInfo* = object
    ## Meta-data describing a NamedAtlas
    name*: string ## name of the Atlas in an AtlasManager
    description*: string ## description of the NamedAtlas
    authors*: seq[string] ## authors of the NamedAtlas
    filename*: string ## filename used to load the NamedAtlas
    width*: int ## the width of the NamedAtlas partitions
    height*: int ## the height of the NamedAtlas partitions
    names*: seq[string] ## names of the NamedAtlas partitions

  NamedAtlas* = ref object
    ## Used for rendering sub-regions of a Texture by name
    info*: NamedAtlasInfo ## meta-data describing the NamedAtlas
    atlas: Atlas ## Atlas underlying the NamedAtlas

  NamedAtlasManager* = ref object
    ## Used for loading and managing NamedAtlases
    atlases: AtlasManager ## Atlases backing managed NamedAtlases
    registry: Table[string, NamedAtlas] ## loaded NamedAtlases by name

proc newNamedAtlasManager*(window: WindowPtr, display: RendererPtr): NamedAtlasManager =
  new(result)
  result.atlases = newAtlasManager(window, display)
  result.registry = initTable[string, NamedAtlas]()

proc load*(tmm: NamedAtlasManager,
           name, filename: string,
           width, height: int,
           names: seq[string],
           description: string = nil,
           authors: seq[string] = nil): NamedAtlas =
  ## Load an image resource from disk, partitioned into sub-regions of t_width and
  ## t_height. Once loaded sub-regions my be rendered by index or by name. Names are
  ## assigned to sub-regions by the order in which they appear in the names sequence.
  if tmm.registry.hasKey(name):
    return tmm.registry[name]

  let
    atlas = tmm.atlases.load(name, filename, width, height)
    info = NamedAtlasInfo(name:name, filename:filename,
                     width:width, height:height,
                     names:names, description:description,
                     authors:authors)
  result = NamedAtlas(info:info, atlas:atlas)
  tmm.registry[name] = result

proc loadPack*(tsm: NamedAtlasManager, filename: string) =
  ## Load a resource-pack of NamedAtlases. NamedAtlases inside of a NamedAtlas resource-pack
  ## should be unmarshalable by the **NamedAtlasAsset** type.
  ##
  ## **Example NamedAtlasInfo JSON**
  ##
  ## .. code-block:: nimrod
  ##    "example_atlas_asset": {
  ##      "filename": "atlases/example_atlas.png",
  ##      "width": 32, "height": 32,
  ##      "names": ["dirt", "grass", "stone", "water", "ice"]
  ##    }
  let pack = loadPack(filename)

  for name, asset_data in pack:
    let info = to[NamedAtlasInfo]($asset_data)
    discard tsm.load(name, info.filename,
                     info.width, info.height, info.names,
                     info.description, info.authors)

proc get*(tmm: NamedAtlasManager, name: string): NamedAtlas =
  ## Get a loaded NamedAtlas by name
  if not tmm.registry.hasKey(name):
    let msg = "No atlas with name `" & name & "` is loaded."
    raise newException(NoSuchResourceError, msg)
  tmm.registry[name]

proc render*(display: RendererPtr, atlas: NamedAtlas, name: string, dx, dy: int) =
  ## Render a region from the NamedAtlas to dx, dy
  for i in 0..atlas.info.names.len - 1:
    if atlas.info.names[i] == name:
      display.render(atlas.atlas, i, dx, dy)
      return


