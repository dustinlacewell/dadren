import tables
import utils
import math
import strutils
import sequtils

type
  Tile* = ref object of RootObj

  Chunk* = TableRef[Point, Tile]

  Generator* = ref object of RootObj

  Tilemap* = ref object
    chunk_size: Size
    chunks: Table[Point, Chunk]
    generator: Generator

proc newChunk*(): Chunk = newTable[Point, Tile]()

method makeChunk(generator: Generator, pos: Point, size: Size): Chunk =
  quit "Generator type must override newChunk"

method visibleTile*(t: Tile): string =
  quit "Tile type must override visibleTile"

proc newTilemap*(generator: Generator, chunk_size: Size): Tilemap =
  new(result)
  result.chunk_size = chunk_size
  result.generator = generator
  result.chunks = initTable[Point, Chunk]()

proc getChunk(tm: Tilemap, x, y: int): Chunk =
  if (x, y) notin tm.chunks:
    let new_chunk = tm.generator.makeChunk((x, y), tm.chunk_size)
    tm.chunks[(x, y)] = new_chunk
    return new_chunk
  tm.chunks[(x, y)]

proc chunkPosition*(tm: Tilemap, x, y: int): Point =
  var
    x_pos = floor(x / tm.chunk_size.w).int
    y_pos = floor(y / tm.chunk_size.h).int

  (x:x_pos, y:y_pos)

proc tilePosition(tm: Tilemap, x, y: int): Point =
  var
    x_pos = x mod tm.chunk_size.w
    y_pos = y mod tm.chunk_size.h

  (x:x_pos.int, y:y_pos.int)

proc getTile*(tm: Tilemap, x, y: int): Tile =
  let
    chunk_position = tm.chunkPosition(x, y)
    tile_position = tm.tilePosition(x, y)

  if chunk_position notin tm.chunks:
    tm.chunks[chunk_position] = tm.getChunk(x, y)

  tm.chunks[chunk_position][tile_position]
