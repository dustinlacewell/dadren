import tables
import json
import macros
import strutils

import sdl2
import random

import dadren/application
import dadren/scenes
import dadren/tilepacks
import dadren/entities
import dadren/tilemap
import dadren/utils


var rng = initMersenneTwister(urandom(2500))

# generate test json entity templates
let templates = parseJson("""
{
 "tree": {
   "Position": { },
   "Velocity": { },
   "Icon": {"rune": "maple"}
 }
}
""")


type
  GameTile* = ref object of Tile
    entity: int
  TreeGenerator* = ref object of Generator
    entities: EntityManager
  GameScene = ref object of Scene
    app: App
    tilepack: Tilepack
    tilemap: Tilemap
    entities: EntityManager

method newChunk*(generator: TreeGenerator, pos: utils.Point, size: Size): Chunk =
  result = newChunk()
  for x in pos.x..(pos.x + size.w):
    for y in pos.y..(pos.y + size.h):
      let e = generator.entities.create("tree")
      result.add((x, y), GameTile(entity: e.id))

proc newGameScene(app: App): GameScene =
  new(result)
  result.app = app
  result.entities = newEntityManager()
  let generator = TreeGenerator(entities: result.entities)
  result.tilemap = generator.newTilemap((10, 10))

method update(self: GameScene, t, dt: float) =
  var
    width: cint
    height: cint
  self.app.display.getLogicalSize(width, height)

  let
    tile_size = self.tilepack.info.tile_size
    max_width = float(width - tile_size.width)
    max_height = float(height - tile_size.height)

  for e in self.entities.has(Position, Velocity):
    e.position.x += e.velocity.dx * dt
    e.position.y += e.velocity.dy * dt

    if e.position.x < 0:
      e.position.x = 0
      e.velocity.dx *= -1

    if e.position.y < 0:
      e.position.y = 0
      e.velocity.dy *= -1

    if e.position.x >= max_width:
      e.position.x = max_width
      e.velocity.dx *= -1

    if e.position.y >= max_height:
      e.position.y = max_height
      e.velocity.dy *= -1

method draw(self: GameScene) =
  for i in self.entities.has(Position, Icon):
    self.app.display.render(self.tilepack, i.icon.rune,
                             int(i.position.x),
                             int(i.position.y))

method enter(self: GameScene) =
  # load the terrain texture atlas into game state
  self.tilepack = self.app.resources.tilepacks.load("retrodays")
  self.entities.load(templates) # load entity templates from json

  for i in 0..500:
    let tree = self.entities.create("tree")
    tree.position.x = self.app.settings.resolution.width / 2
    tree.position.y = self.app.settings.resolution.height / 2
    tree.velocity.dx = rng.random(200) - 50
    tree.velocity.dy = rng.random(200) - 50

let
  app = newApp("settings.json")
  scene = newGameScene(app)

scene.draw()
app.run(scene)
