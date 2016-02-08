import tables
import utils

type
  Tile* = ref object of RootObj

  Chunk* = TableRef[Point, Tile]

  Generator* = ref object of RootObj

  Tilemap* = ref object
    chunk_size: Size
    chunks: Table[Point, Chunk]
    generator: Generator

method newChunk(generator: Generator, pos: Point, size: Size): Chunk =
  quit "Generator type must override newChunk"

proc newChunk*(): Chunk = newTable[Point, Tile]()

proc newTilemap*(generator: Generator, chunk_size: Size): Tilemap =
  new(result)
  result.chunk_size = chunk_size
  result.generator = generator
  result.chunks = initTable[Point, Chunk]()

proc getChunk(tm: Tilemap, x, y: int): Chunk =
  if (x, y) notin tm.chunks:
    let new_chunk = tm.generator.newChunk((x, y), tm.chunk_size)
    tm.chunks[(x, y)] = new_chunk
    return new_chunk

  tm.chunks[(x, y)]
