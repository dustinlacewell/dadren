import os
import marshal
import tables

import sdl2, sdl2/gfx, sdl2/image

import dadren/textures
import dadren/resources
import dadren/exceptions

type
  AtlasInfo* = object
    filename*: string
    name*: string
    width*, height*: int

  Atlas* = object
    info*: AtlasInfo
    texture*: Texture

  AtlasManagerObj = object
    resources: ResourceManager
    registry: Table[string, Atlas]
  AtlasManager* = ref AtlasManagerObj

proc loadAtlasInfo*(filename: string): AtlasInfo =
  try:
    let json_data = readFile(filename)
    result = to[AtlasInfo](json_data) # unmarshal
  except IOError:
    let msg = "The resource `" & filename & "` could not be found."
    raise newException(InvalidResourceError, msg)

proc newAtlasManager*(resources: ResourceManager): AtlasManager =
  new(result)
  result.resources = resources
  result.registry = initTable[string, Atlas]()

proc load*(am: AtlasManager, info: AtlasInfo): Atlas =
  if not existsFile(info.filename):
    let msg = "The atlas texture `" & info.filename & "` could not be found."
    raise newException(InvalidResourceError, msg)
  result.info = info
  try:
    result.texture = am.resources.loadTexture(info.name, info.filename)
  except:
    let msg = "The atlas texture `" & info.filename & "` failed to load."
    raise newException(InvalidResourceError, msg)
  am.registry[info.name] = result

proc load*(am: AtlasManager, name, filename: string, width, height: int): Atlas =
  let info = AtlasInfo(name: name, filename: filename, width: width, height: height)
  result = load(am, info)

proc get*(am: AtlasManager, name: string): Atlas =
  if not am.registry.hasKey(name):
    let msg = "No atlas with name `" & name & "` is loaded."
    raise newException(NoSuchResourceError, msg)
  am.registry[name]
