import os
import tables

import sdl2, sdl2/image

import dadren/textures
import dadren/atlases
import dadren/tilepacks
import dadren/tilesets
import dadren/exceptions

type
  ResourceManagerObj = object
    window*: WindowPtr
    display*: RendererPtr
    textures*: TextureManager
    atlases*: AtlasManager
    tilesets*: TilesetManager
    tilepacks*: TilepackManager
  ResourceManager* = ref ResourceManagerObj

proc newResourceManager*(window: WindowPtr,
                         display: RendererPtr,
                         tileset_path: string): ResourceManager =
  new(result)
  result.window = window
  result.display = display
  result.textures = newTextureManager(window, display)
  result.atlases = newAtlasManager(result.textures)
  result.tilesets = newTilesetManager(result.atlases)
  result.tilepacks = newTilepackManager(result.tilesets, tileset_path)

proc destroy*(rm: ResourceManager) =
  rm.display = nil
  rm.textures.destroy
