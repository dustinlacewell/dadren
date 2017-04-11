import tables

import ./utils

type
  Tile* = ref object of RootObj

  Chunk* = TableRef[Point[int], Tile]

method tile_name*(t: Tile): string {.base.} =
  quit "Tile type must override tile_name"

proc newChunk*(): Chunk = newTable[Point[int], Tile]()
