import os
import tables

import sdl2, sdl2/image

import dadren/textures
import dadren/atlases
import dadren/tilemaps
import dadren/tilesets
import dadren/exceptions

type
  ResourceManagerObj = object
    window*: WindowPtr
    display*: RendererPtr
    textures*: TextureManager
    atlases*: AtlasManager
    tilemaps*: TilemapManager
    tilesets*: TilesetManager
  ResourceManager* = ref ResourceManagerObj

proc newResourceManager*(window: WindowPtr,
                         display: RendererPtr,
                         tilemap_path: string): ResourceManager =
  new(result)
  result.window = window
  result.display = display
  result.textures = newTextureManager(window, display)
  result.atlases = newAtlasManager(result.textures)
  result.tilemaps = newTilemapManager(result.atlases)
  result.tilesets = newTilesetManager(result.tilemaps, tilemap_path)

proc destroy*(rm: ResourceManager) =
  rm.display = nil
  rm.textures.destroy
