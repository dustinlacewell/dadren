import sdl2

import tables

import dadren/atlases
import dadren/exceptions
import dadren/utils

type
  Point = tuple[x, y: int]
  TileTable = Table[string, Point]

  TilemapInfo = object
    name*, filename*: string
    tiles*: TileTable

  TilemapObj = object
    info*: TilemapInfo
    atlas: Atlas
  Tilemap* = ref TilemapObj

  TilemapManagerObj = object
    atlases: AtlasManager
    registry: Table[string, Tilemap]
  TilemapManager* = ref TilemapManagerObj

proc newTilemapInfo*(name, filename: string, tiles: TileTable): TilemapInfo =
  result.name = name
  result.filename = filename
  result.tiles = tiles

proc newTilemap*(info: TilemapInfo, atlas: Atlas): Tilemap =
  new(result)
  result.info = info
  result.atlas = atlas

proc newTilemapManager*(atlases: AtlasManager): TilemapManager =
  new(result)
  result.atlases = atlases
  result.registry = initTable[string, Tilemap]()

proc getTileTable*(atlas: Atlas, tiles: seq[string]): TileTable =
  result = initTable[string, Point]()
  var i = 0
  for tile in tiles:
    result[tile] = atlas.calculateTilePosition(i)
    i = i + 1

proc load*(tmm: TilemapManager,
           name, filename: string,
           t_width, t_height: int,
           tiles: seq[string]): Tilemap =
  if tmm.registry.hasKey(name):
    return tmm.registry[name]

  let
    atlas = tmm.atlases.load(name, filename, t_width, t_height)
    tile_table = atlas.getTileTable(tiles)
    info = newTilemapInfo(name, filename, tile_table)
  result = newTilemap(info, atlas)
  tmm.registry[name] = result

proc get*(tmm: TilemapManager, name: string): Tilemap =
  if not tmm.registry.hasKey(name):
    let msg = "No tilemap with name `" & name & "` is loaded."
    raise newException(NoSuchResourceError, msg)
  tmm.registry[name]

proc render*(display: RendererPtr, tilemap: Tilemap, name: string, dx, dy: int) =
  let (tx, ty) = tilemap.info.tiles[name]
  display.render(tilemap.atlas, tx, ty, dx, dy)


