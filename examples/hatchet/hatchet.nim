import future
import tables
import json
import macros
import strutils
import sequtils

import sdl2
import random

import dadren/application
import dadren/scenes
import dadren/biomes
import dadren/tilepacks
import dadren/entities
import dadren/tilemap
import dadren/camera
import dadren/utils


var rng = initMersenneTwister(urandom(2500))

# generate test json entity templates
let templates = parseJson("""
{
 "tree": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "maple"}
 },
 "water": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "water"}
 },
 "dirt": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "dirt"}
 },
 "grass": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "grass"}
 },
 "snow": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "snow"}
 }
}
""")


type
  GameTile* = ref object of Tile
    entity*: Entity
  TreeGenerator* = ref object of Generator
    entities: EntityManager
    biomes: seq[Biome[Entity]]
  GameScene = ref object of Scene
    app: App
    tilepack: Tilepack
    tilemap: Tilemap
    camera: Camera
    entities: EntityManager

method visibleTile*(t: GameTile): string =
  if Icon in t.entity:
    return t.entity.icon.rune

method makeChunk*(generator: TreeGenerator, pos: utils.Point, size: Size): Chunk =
  let
    kinds = toSeq(generator.entities.templates.keys)

  result = newChunk()
  for x in 0..size.w:
    let rx = pos.x + x
    for y in 0..size.h:
      let ry = pos.y + y
      result.add((x, y), GameTile(entity: generator.biomes.getBiomeValue(rx, ry)))

proc newGameScene(app: App): GameScene =
  let biome_min = 0.025
  var entities = newEntityManager()
  let
    render_size = app.getLogicalSize()
    generator = TreeGenerator(entities: entities, biomes: @[
      newBiome[Entity]((d: float) => (if d > biome_min: entities.create("water") else: entities.create("dirt"))),
      newBiome[Entity]((d: float) => (if d > biome_min: entities.create("tree") else: entities.create("dirt"))),
      newBiome[Entity]((d: float) => (if d > biome_min: entities.create("grass") else: entities.create("dirt"))),
      newBiome[Entity]((d: float) => (if d > biome_min: entities.create("snow") else: entities.create("dirt"))),
    ])

  new(result)
  result.app = app
  result.entities = entities
  result.tilepack = app.resources.tilepacks.load("retrodays")
  result.tilemap = newTilemap(generator, (8, 8))
  result.camera = newCamera((0, 0), (render_size.w, render_size.h), result.tilepack)
  result.camera.attach(result.tilemap)
  result.entities.load(templates) # load entity templates from json

converter scancode2uint8(x: Scancode): cint = cint(x)
converter uint82bool(x: uint8):bool  = bool(x)

method update(self: GameScene, t, dt: float) =
  let keys = getKeyboardState()

  if keys[SDL_SCANCODE_LEFT.cint]:
    self.camera.move(-1, 0)
  elif keys[SDL_SCANCODE_RIGHT.cint]:
    self.camera.move(1, 0)
  if keys[SDL_SCANCODE_UP.cint]:
    self.camera.move(0, -1)
  elif keys[SDL_SCANCODE_DOWN.cint]:
    self.camera.move(0, 1)

proc handle_key(gs: GameScene, keysym: KeySym) =
  case keysym.sym:
    of K_LEFT: gs.camera.move(-1, 0)
    of K_RIGHT: gs.camera.move(1, 0)
    of K_UP: gs.camera.move(0, -1)
    of K_DOwN: gs.camera.move(0, 1)
    else: discard

# method handle(self: GameScene, event: Event) =
#   case event.kind:
#     of KeyDown:
#       self.handle_key(event.key.keysym)
#     else: discard

method draw(self: GameScene) =
  self.camera.render(self.app.display)

let
  app = newApp("settings.json")
  scene = newGameScene(app)

scene.draw()
app.run(scene)
