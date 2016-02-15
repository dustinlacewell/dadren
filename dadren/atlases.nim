import os
import marshal
import tables

import sdl2, sdl2/image

import ./textures
import ./exceptions
import ./utils

type
  AtlasInfo* = object
    name, filename*: string
    size*: Size
    tile_size*: Size

  AtlasObj* = object
    info*: AtlasInfo
    texture*: Texture
  Atlas* = ref AtlasObj

  AtlasManagerObj = object
    textures: TextureManager
    registry: Table[string, Atlas]
  AtlasManager* = ref AtlasManagerObj

proc newAtlasInfo*(name, filename: string, size, tile_size: Size): AtlasInfo =
  result.name = name
  result.filename = filename
  result.size = size
  result.tile_size = tile_size

proc newAtlas*(info: AtlasInfo, texture: Texture): Atlas =
  new(result)
  result.info = info
  result.texture = texture

proc newAtlasManager*(tm: TextureManager): AtlasManager =
  new(result)
  result.textures = tm
  result.registry = initTable[string, Atlas]()

proc calculateAtlasSize(texture: Texture, tile_size: Size): Size =
  result.w = texture.info.size.w /% tile_size.w
  result.h = texture.info.size.h /% tile_size.h

proc validateTileSize(info: AtlasInfo, texture: Texture) =
  # ensure the tile_size evenly divides into the Texture
  if (texture.info.size.w %% info.tile_size.w != 0 or
      texture.info.size.h %% info.tile_size.h != 0):
    let msg = "Atlas dimensions for `" & info.name & "` are incompatible with associated texture."
    raise newException(InvalidResourceError, msg)

proc load*(am: AtlasManager, name, filename: string, t_width, t_height: int): Atlas =
  if am.registry.hasKey(name):
    return am.registry[name]

  let
    texture = am.textures.load(name, filename)
    tile_size = (t_width, t_height)
    atlas_size = texture.calculateAtlasSize(tile_size)
    info = newAtlasInfo(name, filename, atlas_size, tile_size)

  validateTileSize(info, texture)
  result = newAtlas(info, texture)
  am.registry[name] = result

proc get*(am: AtlasManager, name: string): Atlas =
  if not am.registry.hasKey(name):
    let msg = "No atlas with name `" & name & "` is loaded."
    raise newException(NoSuchResourceError, msg)
  am.registry[name]

proc calculateTilePosition*(atlas: Atlas, n): tuple[x, y: int] =
  ((if n > 0: n %% atlas.info.size.w else: 0),
   (if n > 0: n /% atlas.info.size.w else: 0))

proc render*(display: RendererPtr, atlas: Atlas, tx, ty, dx, dy: int) =
  let
    sx = tx *% atlas.info.tile_size.w
    sy = ty *% atlas.info.tile_size.h

  display.render(atlas.texture, sx, sy, dx, dy,
                 atlas.info.tile_size.w,
                 atlas.info.tile_size.h)

proc render*(display: RendererPtr, atlas: Atlas, n, dx, dy: int) =
  let (tx, ty) = atlas.calculateTilePosition(n)
  display.render(atlas, tx, ty, dx, dy)
