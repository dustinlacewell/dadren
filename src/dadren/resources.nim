import os
import tables

import sdl2, sdl2/image

import dadren/textures
import dadren/exceptions

type
  ResourceManagerObj = object
    window*: WindowPtr
    display*: RendererPtr
    textures*: Table[string, Texture]
  ResourceManager* = ref ResourceManagerObj

proc newResourceManager*(window: WindowPtr, display: RendererPtr): ResourceManager =
  new(result)
  result.window = window
  result.display = display
  result.textures = initTable[string, Texture]()

proc destroy*(rm: ResourceManager) =
  rm.display = nil
  for name, texture in rm.textures.pairs():
    texture.destroy
  rm.textures = initTable[string, Texture]()

proc loadTexture*(rm: ResourceManager, name, filename: string): Texture =
  result = loadTexture(rm.window, rm.display, name, filename)
  rm.textures[name] = result

proc getTexture*(rm: ResourceManager, name: string): Texture =
  if not rm.textures.hasKey(name):
    let msg = "No texture with name `" & name & "` is loaded."
    raise newException(NoSuchResourceError, msg)
  rm.textures[name]
