import os
import tables
import marshal

import sdl2

import dadren/exceptions
import dadren/tilemaps
import dadren/utils

type
  TilemapTable = Table[string, Tilemap]

  TilesetInfo = object
    name*, label*: string
    path*: string
    authors*: seq[string]
    tile_size*: Resolution

  TilemapData = object
    name: string
    filename: string
    tiles: seq[string]

  TilesetData = object
    info*: TilesetInfo
    tilemaps: seq[TilemapData]

  TilesetObj = object
    info*: TilesetInfo
    tilemaps: TilemapTable
    tiles: TilemapTable
  Tileset* = ref TilesetObj

  TilesetManagerObj = object
    path: string
    tilemaps: TilemapManager
    registry: Table[string, Tileset]
  TilesetManager* = ref TilesetManagerObj

proc loadTileset*(path: string): TilesetData =
  let filename = path / "tileset.json"
  if not existsFile(filename):
    let msg = "The tileset configuration `" & filename & "` was not found."
    raise newException(NoSuchResourceError, msg)

  let
    json_data = readFile(filename)
  result = to[TilesetData](json_data)
  result.info.path = path # remember the path the tileset was loaded from

proc newTileset*(info: TilesetInfo,
                 tilemaps: TilemapTable, tiles: TilemapTable): Tileset =
  new(result)
  result.info = info
  result.tilemaps = tilemaps
  result.tiles = tiles

proc newTilesetManager*(tmm: TilemapManager, path: string): TilesetManager =
  new(result)
  result.path = path
  result.tilemaps = tmm
  result.registry = initTable[string, Tileset]()

proc loadTilemaps(tsm: TilesetManager, tileset: TilesetData): TilemapTable =
  result = initTable[string, Tilemap]()
  for tilemap in tileset.tilemaps:
    let filename = tileset.info.path / tilemap.filename
    result[tilemap.name] = tsm.tilemaps.load(tilemap.name, filename,
                                             tileset.info.tile_size.width,
                                             tileset.info.tile_size.height,
                                             tilemap.tiles)

proc cacheLookups(table: TilemapTable): TilemapTable =
  # create a global tile->tilemap table
  result = initTable[string, Tilemap]()
  for name, tilemap in table.pairs:
    for tile in tilemap.info.tiles.keys():
      result[tile] = tilemap

proc load*(tsm: TilesetManager, name): Tileset =
  if tsm.registry.hasKey(name):
    return tsm.registry[name]

  let
    tileset_path = tsm.path / name
    tileset_data = loadTileset(tileset_path)
    tilemap_table = tsm.loadTilemaps(tileset_data)
    tilemap_tiles = tilemap_table.cacheLookups()
  result = newTileset(tileset_data.info, tilemap_table, tilemap_tiles)
  tsm.registry[name] = result

proc get*(tsm: TilesetManager, name): Tileset =
  if not tsm.registry.hasKey(name):
    let msg = "No tileset with name `" & name & "` is loaded."
    raise newException(NoSuchResourceError, msg)
  tsm.registry[name]

proc render*(display: RendererPtr, tileset: Tileset, name: string, dx, dy: int) =
  let tilemap = tileset.tiles[name]
  display.render(tilemap, name, dx, dy)


