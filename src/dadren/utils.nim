import sdl2, sdl2/image

type
  Resolution* = object
    width*, height*: int

proc newResolution*(width, height: int): Resolution =
  result.width = width
  result.height = height

proc newRect*(x, y, w, h: cint): Rect =
  result.x = x
  result.y = y
  result.w = w
  result.h = h

converter cint2int*(x: cint): int = x.int
converter int2cint*(x: int): cint = x.cint
