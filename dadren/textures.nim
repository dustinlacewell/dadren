import os
import tables

import sdl2, sdl2/image

import ./utils
import ./exceptions

proc loadSurface(window: WindowPtr, filename: string): SurfacePtr =
  if not existsFile(filename):
    let msg = "The image `" & filename & "` does not exist."
    raise newException(InvalidResourceError, msg)
  let
    surface = image.load(filename)
    format = window.getSurface().format
  # return the screen-converted surface
  convertSurface(surface, format, 0)

proc loadTexture*(display: RendererPtr, surface: SurfacePtr): TexturePtr =
  display.createTextureFromSurface(surface)

type
  TextureInfo* = object
    name*, filename*: string
    size*: Size

  TextureObj = object
    info*: TextureInfo
    handle: TexturePtr
  Texture* = ref TextureObj

  TextureManagerObj = object
    window: WindowPtr
    display: RendererPtr
    registry: Table[string, Texture]
  TextureManager* = ref TextureManagerObj

proc newTextureInfo*(name, filename: string, size: Size): TextureInfo =
  result.name = name
  result.filename = filename
  result.size = size

proc newTexture*(info: TextureInfo, handle: TexturePtr): Texture =
  new(result)
  result.info = info
  result.handle = handle

proc destroy*(texture: Texture) =
  texture.handle.destroy
  texture.handle = nil

proc destroy*(tm: TextureManager) =
  for name, texture in tm.registry.pairs:
    texture.destroy
  tm.registry = initTable[string, Texture]()

proc newTextureManager*(window: WindowPtr, display: RendererPtr): TextureManager =
  new(result)
  result.window = window
  result.display = display
  result.registry = initTable[string, Texture]()

proc load*(tm: TextureManager, name, filename: string): Texture =
  if tm.registry.hasKey(name):
    return tm.registry[name]

  if not existsFile(filename):
    let msg = "The texture image `" & filename & "` could not be found."
    raise newException(InvalidResourceError, msg)

  try:
    let
      surface = tm.window.loadSurface(filename)
      size: Size = (surface.w.int, surface.h.int)
      info = newTextureInfo(name, filename, size)
      handle = tm.display.loadTexture(surface)
    result = newTexture(info, handle)
    tm.registry[name] = result
  except:
    let msg = "The texture image `" & filename & "` failed to load."
    raise newException(InvalidResourceError, msg)

proc get*(tm: TextureManager, name: string): Texture =
  if not tm.registry.hasKey(name):
    let msg = "No texture with name `" & name & "` is loaded."
    raise newException(NoSuchResourceError, msg)
  tm.registry[name]

proc render*(display: RendererPtr, texture: Texture, x, y: int) =
  var dst: sdl2.Rect = (x.cint,
                        y.cint,
                        texture.info.size.w.cint,
                        texture.info.size.h.cint)
  display.copy(texture.handle, cast[ptr sdl2.Rect](nil), dst.addr)

proc render*(display: RendererPtr, texture: Texture,
             sx, sy, dx, dy, width, height: int) =
  var
    src = (sx.cint, sy.cint, width.cint, height.cint)
    dst = (dx.cint, dy.cint, width.cint, height.cint)
  display.copy(texture.handle, src.addr, dst.addr)

