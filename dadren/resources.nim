import os
import tables

import sdl2, sdl2/image

import ./textures
import ./atlases
import ./namedatlases
import ./tilesets
import ./exceptions

type
  ResourceManagerObj = object
    window*: WindowPtr
    display*: RendererPtr
    textures*: TextureManager
    atlases*: AtlasManager
    namedatlases*: NamedAtlasManager
    tilesets*: TilesetManager
  ResourceManager* = ref ResourceManagerObj

proc newResourceManager*(window: WindowPtr,
                         display: RendererPtr,
                         tileset_path: string): ResourceManager =
  new(result)
  result.window = window
  result.display = display
  result.textures = newTextureManager(window, display)
  result.atlases = newAtlasManager(window, display)
  result.namedatlases = newNamedAtlasManager(window, display)
  result.tilesets = newTilesetManager(window, display)

proc destroy*(rm: ResourceManager) =
  rm.display = nil
  rm.textures.destroy
