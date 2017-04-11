import tables
import utils
import math
import strutils
import sequtils

import ./chunks
import ./generators
import dadren.utils

type
  Tilemap*[T] = ref object
    chunk_size: Size
    chunks: Table[Point[int], Chunk]
    generator: Generator[T]

proc newTilemap*[T](chunk_size: Size, generator: Generator[T]): Tilemap[T] =
  new(result)
  result.chunk_size = chunk_size
  result.generator = generator
  result.chunks = initTable[Point[int], Chunk]()

proc makeChunk*[T](map: Tilemap[T], pos: Point[int], size: Size): Chunk =
  result = newChunk()
  let
    tx = pos.x * size.w
    ty = pos.y * size.h
  for x in 0..size.w:
    for y in 0..size.h:
      result.add(Point[int](x:x, y:y), map.generator.resolve(tx + x, ty + y))

proc getChunk(tm: Tilemap, pos: Point[int]): Chunk =
  if pos notin tm.chunks:
    let new_chunk = tm.makeChunk(pos, tm.chunk_size)
    tm.chunks[pos] = new_chunk
    return new_chunk
  tm.chunks[pos]

proc chunkPosition*(tm: Tilemap, x, y: int): Point[int] =
  Point[int](
    x: int(floor(x / tm.chunk_size.w)),
    y: int(floor(y / tm.chunk_size.h)))

proc tilePosition(tm: Tilemap, x, y: int): Point[int] =
  Point[int](
    x: int(float(x) mod float(tm.chunk_size.w)),
    y: int(float(y) mod float(tm.chunk_size.h)))

proc getTile*(tm: Tilemap, x, y: int): Tile =
  let
    chunk_position = tm.chunkPosition(x, y)
    tile_position = tm.tilePosition(x, y)
    chunk = tm.getChunk(chunk_position)

  chunk[tile_position]
