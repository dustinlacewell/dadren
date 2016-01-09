import os

import sdl2, sdl2/image

import dadren/exceptions

type
  TextureObj = object
    name, filename: string
    width, height: int
    handle: TexturePtr
  Texture* = ref TextureObj

proc newRect(x, y, w, h: int): Rect =
  result.x = cint x
  result.y = cint y
  result.w = cint w
  result.h = cint h

proc newTexture*(name, filename: string,
                 width, height: int,
                 handle: TexturePtr): Texture =
  new(result)
  result.name = name
  result.filename = filename
  result.width = width
  result.height = height
  result.handle = handle

proc destroy*(texture: Texture) =
  destroy texture.handle
  texture.handle = nil

proc loadSurface(window: WindowPtr, filename: string): SurfacePtr =
  if not existsFile(filename):
    let msg = "The image `" & filename & "` does not exist."
    raise newException(InvalidResourceError, msg)
  let
    surface = image.load(filename)
    format = window.getSurface().format
  # return the screen-converted surface
  convertSurface(surface, format, 0)

proc loadTexture*(window: WindowPtr, display: RendererPtr,
                  name, filename: string): Texture =
  if not existsFile(filename):
    let msg = "The image `" & filename & "` does not exist."
    raise newException(InvalidResourceError, msg)
  let
    surface = window.loadSurface(filename)
    texture = createTextureFromSurface(display, surface)
  newTexture(name, filename, surface.w, surface.h, texture)

proc render*(display: RendererPtr, texture: Texture, x, y: int) =
  var dst = newRect(x, y, texture.width, texture.height)
  display.copy(texture.handle, nil, dst.addr)

proc render*(display: RendererPtr, texture: Texture,
             sx, sy, dx, dy, width, height: int) =
  var
    src = newRect(sx, sy, width, height)
    dst = newRect(dx, dy, width, height)
  display.copy(texture.handle, src.addr, dst.addr)

