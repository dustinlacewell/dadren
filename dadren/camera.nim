import future
import tables
import math
import sequtils
import strutils

import random
from sdl2 import RendererPtr

import dadren/tilemap
import dadren/tilesets
import dadren/utils
import dadren/tilepacks


type
  Camera* = ref object
    position: Point
    size: Size
    tilepack: Tilepack
    map: Tilemap
    focus: Point

proc newCamera*(position: Point, size: Size, tilepack: Tilepack): Camera =
  new(result)
  result.position = position
  result.size = size
  result.tilepack = tilepack
  result.map = nil
  result.focus = (0, 0)

proc attach*(camera: Camera, map: Tilemap, focus: Point = (0, 0)) =
  camera.map = map
  camera.focus = focus

proc maxWidth(camera: Camera): int =
  floor(camera.size.w / camera.tilepack.info.tile_size.width).int

proc maxHeight(camera: Camera): int =
  floor(camera.size.h / camera.tilepack.info.tile_size.height).int

proc render*(camera: Camera, display: RendererPtr) =
  let
    tw = camera.tilepack.info.tile_size.width
    th = camera.tilepack.info.tile_size.height
    fx = (camera.focus.x - int(floor(float(camera.maxWidth) / 2.0))) + 1073741823
    fy = (camera.focus.y - int(floor(float(camera.maxHeight) / 2.0))) + 1073741823
    px = camera.position.x
    py = camera.position.y


  for x in 0..camera.maxWidth - 1:
    let sx = px + (x * tw) # horizontal screen position
    for y in 0..camera.maxHeight - 1:
      let
        sy = py + (y * th) # vertical screen position
        tile = camera.map.getTile(fx + x, fy + y) # tile object from map
        name = tile.visibleTile() # tile name from tilepack
      display.render(camera.tilepack, name, sx, sy)

proc move*(camera: Camera, x, y: int) =
  camera.focus.x += x
  camera.focus.y += y
  let
    cp = camera.map.chunkPosition(camera.focus.x, camera.focus.y)
