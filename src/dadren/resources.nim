import os
import tables

import sdl2, sdl2/image

import dadren/textures
import dadren/atlases
import dadren/exceptions

type
  ResourceManagerObj = object
    window*: WindowPtr
    display*: RendererPtr
    textures*: TextureManager
    atlases*: AtlasManager
  ResourceManager* = ref ResourceManagerObj

proc newResourceManager*(window: WindowPtr, display: RendererPtr): ResourceManager =
  new(result)
  result.window = window
  result.display = display
  result.textures = newTextureManager(window, display)
  result.atlases = newAtlasManager(result.textures)

proc destroy*(rm: ResourceManager) =
  rm.display = nil
  rm.textures.destroy
