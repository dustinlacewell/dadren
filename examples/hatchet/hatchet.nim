import json
import macros
import strutils

import sdl2
import random

import dadren/application
import dadren/scenes
import dadren/tilesets
import dadren/entities

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
  GameScene = ref object of Scene
    app: App
    tileset: Tileset
    entities: EntityManager

proc newGameScene(app: App): GameScene =
  new(result)
  result.app = app
  result.entities = newEntityManager()

method update(self: GameScene, t, dt: float) =
  let
    resolution = self.app.settings.resolution
    tile_size = self.tileset.info.tile_size
    max_width = float(resolution.width - tile_size.width)
    max_height = float(resolution.height - tile_size.height)

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
    self.app.display.render(self.tileset, i.icon.rune,
                             int(i.position.x),
                             int(i.position.y))

method enter(self: GameScene) =
  # load the terrain texture atlas into game state
  self.tileset = self.app.resources.tilesets.load("retrodays")
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
