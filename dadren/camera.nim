import future
import tables
import math
import sequtils
import strutils

import random
from sdl2 import RendererPtr

import ./chunks
import ./tilemap
import ./tilesets
import ./utils
import ./tilepacks


type
  Camera*[T] = ref object
    position: Point[int]
    size: Size
    tilepack: Tilepack
    map*: Tilemap[T]
    focus: Point[int]

proc newCamera*[T](position: Point[int], size: Size, tilepack: Tilepack): Camera[T] =
  new(result)
  result.position = position
  result.size = size
  result.tilepack = tilepack
  result.map = nil
  result.focus = Point[int](x:0, y:0)

proc maxWidth[T](camera: Camera[T]): int =
  floor(camera.size.w / camera.tilepack.info.tile_size.width).int - 1

proc maxHeight[T](camera: Camera[T]): int =
  floor(camera.size.h / camera.tilepack.info.tile_size.height).int - 1

proc attach*[T](camera: Camera[T], map: Tilemap[T], focus: Point[int] = Point[int](x:0, y:0)) =
  camera.map = map
  camera.focus = focus

proc render*[T](camera: Camera[T], display: RendererPtr) =
  let
    tw = camera.tilepack.info.tile_size.width
    th = camera.tilepack.info.tile_size.height
    fx = camera.focus.x
    fy = camera.focus.y
    px = camera.position.x
    py = camera.position.y

  var
    sx = 0
    sy = 0

  for x in 0..camera.maxWidth:
    sx = px + (x * tw) # horizontal screen position
    for y in 0..camera.maxHeight:
      let
        sy = py + (y * th) # vertical screen position
        tile = camera.map.getTile(fx + x, fy + y) # tile object from map
        name = tile.tile_name # tile name from tilepack
      display.render(camera.tilepack, tile.tile_name, sx, sy)

proc move*[T](camera: Camera[T], x, y: int) =
  camera.focus.x += x
  camera.focus.y += y
