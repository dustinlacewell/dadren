import os
import tables
import marshal

import sdl2

import dadren/exceptions
import dadren/tilesets
import dadren/utils

type
  TilesetTable = Table[string, Tileset]

  TilepackInfo = object
    name*, label*: string
    path*: string
    authors*: seq[string]
    tile_size*: Resolution

  TilesetData = object
    name: string
    filename: string
    tiles: seq[string]

  TilepackData = object
    info*: TilepackInfo
    tilesets*: seq[TilesetData]

  TilepackObj = object
    info*: TilepackInfo
    tilesets: TilesetTable
    tiles*: TilesetTable
  Tilepack* = ref TilepackObj

  TilepackManagerObj = object
    path: string
    tilesets: TilesetManager
    registry: Table[string, Tilepack]
  TilepackManager* = ref TilepackManagerObj

proc loadTilepack*(path: string): TilepackData =
  let filename = path / "tilepack.json"
  if not existsFile(filename):
    let msg = "The tilepack configuration `" & filename & "` was not found."
    raise newException(NoSuchResourceError, msg)

  let
    json_data = readFile(filename)
  result = to[TilepackData](json_data)
  result.info.path = path # remember the path the tilepack was loaded from

proc newTilepack*(info: TilepackInfo,
                 tilesets: TilesetTable, tiles: TilesetTable): Tilepack =
  new(result)
  result.info = info
  result.tilesets = tilesets
  result.tiles = tiles

proc newTilepackManager*(tmm: TilesetManager, path: string): TilepackManager =
  new(result)
  result.path = path
  result.tilesets = tmm
  result.registry = initTable[string, Tilepack]()

proc loadTilesets(tsm: TilepackManager, tilepack: TilepackData): TilesetTable =
  result = initTable[string, Tileset]()
  for tileset in tilepack.tilesets:
    let filename = tilepack.info.path / tileset.filename
    result[tileset.name] = tsm.tilesets.load(tileset.name, filename,
                                             tilepack.info.tile_size.width,
                                             tilepack.info.tile_size.height,
                                             tileset.tiles)

proc cacheLookups(table: TilesetTable): TilesetTable =
  # create a global tile->tileset table
  result = initTable[string, Tileset]()
  for name, tileset in table.pairs:
    for tile in tileset.info.tiles.keys():
      result[tile] = tileset

proc load*(tsm: TilepackManager, name): Tilepack =
  if tsm.registry.hasKey(name):
    return tsm.registry[name]

  let
    tilepack_path = tsm.path / name
    tilepack_data = loadTilepack(tilepack_path)
    tileset_table = tsm.loadTilesets(tilepack_data)
    tileset_tiles = tileset_table.cacheLookups()
  result = newTilepack(tilepack_data.info, tileset_table, tileset_tiles)
  tsm.registry[name] = result

proc get*(tsm: TilepackManager, name): Tilepack =
  if not tsm.registry.hasKey(name):
    let msg = "No tilepack with name `" & name & "` is loaded."
    raise newException(NoSuchResourceError, msg)
  tsm.registry[name]

proc render*(display: RendererPtr, tilepack: Tilepack, name: string, dx, dy: int) =
  let tileset = tilepack.tiles[name]
  display.render(tileset, name, dx, dy)


