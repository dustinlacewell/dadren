import future
import sequtils

import random

import sdl2, sdl2/image

type
  Point* = tuple[x, y: int]
  Size* = tuple[w, h: int]
  Region* = tuple[x, y, w, h: int]
  Resolution* = object
    width*, height*: int

converter cint2int*(x: cint): int = x.int
converter int2cint*(x: int): cint = x.cint
converter uint2int*(x: uint): int = x.int
converter int2uint*(x: int): uint = x.uint

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
