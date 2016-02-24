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

type
  Camera*[T] = ref object
    position: Point
    size: Size
    tileset: Tileset
    map*: Tilemap[T]
    focus: Point

proc newCamera*[T](position: Point, size: Size, tileset: Tileset): Camera[T] =
  new(result)
  result.position = position
  result.size = size
  result.tileset = tileset
  result.map = nil
  result.focus = (0, 0)

proc maxWidth[T](camera: Camera[T]): int =
  floor(camera.size.w / camera.tileset.info.width).int - 1

proc maxHeight[T](camera: Camera[T]): int =
  floor(camera.size.h / camera.tileset.info.height).int - 1

proc attach*[T](camera: Camera[T], map: Tilemap[T], focus: Point = (0, 0)) =
  camera.map = map
  camera.focus = focus

proc render*[T](camera: Camera[T], display: RendererPtr) =
  let
    tw = camera.tileset.info.width
    th = camera.tileset.info.height
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
        name = tile.tile_name # tile name from tileset
      display.render(camera.tileset, tile.tile_name, sx, sy)

proc move*[T](camera: Camera[T], x, y: int) =
  camera.focus.x += x
  camera.focus.y += y
