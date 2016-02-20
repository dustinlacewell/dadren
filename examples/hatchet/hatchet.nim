import future
import tables
import json
import macros
import math
import strutils
import sequtils
import marshal

import sdl2
import random

import dadren/application
import dadren/scenes
import dadren/tilepacks
import dadren/chunks
import dadren/generators
import dadren/tilemap
import dadren/camera
import dadren/utils
import dadren/magic

type
  Position* = object
    x*, y*: float

  Velocity* = object
    dx*, dy*: float

  Icon* = object
    rune*: string

aggregate(Entity, [Position, Velocity, Icon])

# generate test json entity templates
let templates = parseJson("""
{
 "dirt": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "dirt"}
 },
 "snow": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "snow"}
 },
 "grass": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "grass"}
 },
 "snowy_grass": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "snowy_grass"}
 },
 "road": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "road"}
 },
 "road_line": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "road_line"}
 },
 "water": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "water"}
 },
 "deep_water": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "deep_water"}
 },
 "ice": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "ice"}
 },
 "stone": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "stone"}
 },
 "marsh": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "marsh"}
 },
 "little_bluestem": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "little_bluestem"}
 },
 "sweetgrass": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "sweetgrass"}
 },
 "big_bluestem": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "big_bluestem"}
 },
 "young_alder": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "young_alder"}
 },
 "mature_alder": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "mature_alder"}
 },
 "maple": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "maple"}
 },
 "larch_bolete": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "larch_bolete"}
 }
}
""")


type
  GameTile* = ref object of Tile
    terrain: Entity
    objects: seq[Entity]
  GameScene = ref object of Scene
    app: App
    tilepack: Tilepack
    tilemap: Tilemap[GameTile]
    camera: Camera[GameTile]
    entities: EntityManager

proc newGameTile(terrain: Entity, objects: seq[Entity] = @[]): GameTile =
  new(result)
  result.terrain = terrain
  result.objects = objects

method tile_name*(self: GameTile): string =
  if self.objects.len == 0:
    return self.terrain.icon.rune
  else:
    for obj in self.objects:
      if Icon in obj:
        return obj.icon.rune

proc newGameScene(app: App): GameScene =
  var entities = newEntityManager()
  entities.load(templates)

  let
    render_size = app.getLogicalSize()
    chunk_size = (8, 8)
    camera_position = (0, 0)
    camera_size = render_size

  new(result)
  result.app = app
  result.entities = entities
  result.tilepack = app.resources.tilepacks.load("retrodays")

  let
    marsh_generator = newRangedGenerator(@[
      (1, newWeightedGenerator(@[
        (2, newStaticGenerator(GameTile(terrain: entities.create("water")))),
        (2, newStaticGenerator(GameTile(terrain: entities.create("marsh")))),
        (1, newStaticGenerator(GameTile(terrain: entities.create("stone")))),
        (1, newStaticGenerator(GameTile(terrain: entities.create("grass")))),
      ])),
      (2, newStaticGenerator(GameTile(terrain: entities.create("water")))),
      (2, newStaticGenerator(GameTile(terrain: entities.create("deep_water")))),
    ], child=true)

    forest_generator = newRangedGenerator(@[
      (50, newWeightedGenerator(@[
        (10, newStaticGenerator(GameTile(terrain: entities.create("dirt")))),
        (2, newStaticGenerator(GameTile(terrain: entities.create("grass")))),
      ])),
      (100, newWeightedGenerator(@[
        (10, newStaticGenerator(GameTile(terrain: entities.create("grass")))),
        (2, newStaticGenerator(GameTile(terrain: entities.create("sweetgrass")))),
        (1, newStaticGenerator(GameTile(terrain: entities.create("big_bluestem")))),
        (1, newStaticGenerator(GameTile(terrain: entities.create("little_bluestem")))),
      ])),
      (250, newWeightedGenerator(@[
        (10, newStaticGenerator(GameTile(terrain: entities.create("sweetgrass")))),
        (2, newStaticGenerator(GameTile(terrain: entities.create("grass")))),
        (2, newStaticGenerator(GameTile(terrain: entities.create("maple")))),
        (1, newStaticGenerator(GameTile(terrain: entities.create("mature_alder")))),
        (1, newStaticGenerator(GameTile(terrain: entities.create("young_alder")))),
      ])),
    ], child=true)

  result.tilemap = newTilemap(chunk_size, newBillowGenerator(@[
    marsh_generator, forest_generator
  ], scale=4.0, jitter=0.05))

  # result.tilemap = newTilemap(chunk_size, newBillowGenerator(@[
  #   newStaticGenerator(GameTile(terrain: entities.create("grass"))),
  #   newStaticGenerator(GameTile(terrain: entities.create("water"))),
  # ]))

  result.camera = newCamera[GameTile](camera_position, camera_size, result.tilepack)
  result.camera.attach(result.tilemap)

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
