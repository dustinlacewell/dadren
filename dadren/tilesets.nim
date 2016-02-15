import sdl2

import tables

import ./atlases
import ./exceptions
import ./utils

type
  TileTable = Table[string, utils.Point]

  TilesetInfo = object
    name*, filename*: string
    tiles*: TileTable

  TilesetObj = object
    info*: TilesetInfo
    atlas: Atlas
  Tileset* = ref TilesetObj

  TilesetManagerObj = object
    atlases: AtlasManager
    registry: Table[string, Tileset]
  TilesetManager* = ref TilesetManagerObj

proc newTilesetInfo*(name, filename: string, tiles: TileTable): TilesetInfo =
  result.name = name
  result.filename = filename
  result.tiles = tiles

proc newTileset*(info: TilesetInfo, atlas: Atlas): Tileset =
  new(result)
  result.info = info
  result.atlas = atlas

proc newTilesetManager*(atlases: AtlasManager): TilesetManager =
  new(result)
  result.atlases = atlases
  result.registry = initTable[string, Tileset]()

proc getTileTable*(atlas: Atlas, tiles: seq[string]): TileTable =
  result = initTable[string, utils.Point]()
  var i = 0
  for tile in tiles:
    result[tile] = atlas.calculateTilePosition(i)
    i = i + 1

proc load*(tmm: TilesetManager,
           name, filename: string,
           t_width, t_height: int,
           tiles: seq[string]): Tileset =
  if tmm.registry.hasKey(name):
    return tmm.registry[name]

  let
    atlas = tmm.atlases.load(name, filename, t_width, t_height)
    tile_table = atlas.getTileTable(tiles)
    info = newTilesetInfo(name, filename, tile_table)
  result = newTileset(info, atlas)
  tmm.registry[name] = result

proc get*(tmm: TilesetManager, name: string): Tileset =
  if not tmm.registry.hasKey(name):
    let msg = "No tileset with name `" & name & "` is loaded."
    raise newException(NoSuchResourceError, msg)
  tmm.registry[name]

proc render*(display: RendererPtr, tileset: Tileset, name: string, dx, dy: int) =
  let (tx, ty) = tileset.info.tiles[name]
  display.render(tileset.atlas, tx, ty, dx, dy)


