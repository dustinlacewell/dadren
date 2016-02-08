import sdl2, sdl2/image

type
  Point* = tuple[x, y: int]
  Size* = tuple[w, h: int]
  Region* = tuple[x, y, w, h: int]
  Resolution* = object
    width*, height*: int

converter cint2int*(x: cint): int = x.int
converter int2cint*(x: int): cint = x.cint
