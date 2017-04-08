import future
import sequtils

import random

import sdl2, sdl2/image

type
  Point* = tuple[x, y: int]
  Size* = tuple[w, h: int]
  Rect* = tuple[x, y, w, h: int]
  Resolution* = object
    width*, height*: int

converter to_int*(x: cint): int = x.int
converter to_cint*(x: int): cint = x.cint
converter to_int*(x: uint): int = x.int
converter to_uint*(x: int): uint = x.uint
converter to_cint*(x: float): cint = x.cint
converter to_cint*(x: uint8): cint = x.cint
converter to_float*(x: cint): float = x.float

type Region*[T: int|float] = object
    left*, top*, right*, bottom*: T

proc width*[T](self: Region[T]): T = self.right - self.left
proc height*[T](self: Region[T]): T = self.bottom - self.top
proc midpointW*[T](self: Region[T], position: float): T = self.left + position * self.width
proc midpointH*[T](self: Region[T], position: float): T = self.top + position * self.height

proc weighted_choice*[T](options: seq[(int, T)]): T =
  var sum: int = 0
  for pair in options:
    sum += pair[0]

  var val = random(sum + 1)
  for pair in options:
    val -= pair[0]
    if val <= 0:
      return pair[1]

proc weighted_selection*[T](options: seq[(int, T)], selection: float): T =
  var sum = 0
  for pair in options:
    sum += pair[0]

  var scaled_selection = min(1.0, selection) * float(sum)

  for pair in options:
    scaled_selection -= float(pair[0])
    if scaled_selection <= 0:
      return pair[1]
