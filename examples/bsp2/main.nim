import typetraits
import strutils
import random
import colors

import sdl2

import dadren.application
import dadren.scenes
import dadren.utils
import dadren.bsp

type Colors = enum
  BG = colOlive
  FG = colIndianRed

type
  Pane = ref object
    selected: bool
  GameScene = ref object of Scene
    app: App
    bsp: BSPTree[Pane]
    last: Leaf[Pane]
    maxRatio: float
    minRatio: float
    change: float

proc newPane(): Pane =
  result = new(Pane)
  result.selected = false

proc newGameScene(app: App): GameScene =
  new(result)
  result.app = app
  result.maxRatio = 0.9
  result.minRatio = 0.1
  result.change = 0.01
  let size = app.getLogicalSize()
  result.bsp = newBSPTree(newPane(), 0f, 0f, size.w.float, size.h.float)

method draw(self: BSPNode[Pane], scene: GameScene, depth=0) {.base.} =
  echo "Override this!"

method draw(self: VSplit[Pane], scene: GameScene, depth=0) =
  var
    mp = self.midpoint
    top = int(self.top)
    bottom = int(self.bottom)
  scene.app.display.setDrawColor(255, 255, 255, 255)
  for y in top..bottom:
    scene.app.display.drawPoint(mp, y)

  draw(self.backward, scene, depth+1)
  draw(self.forward, scene, depth+1)

method draw(self: HSplit[Pane], scene: GameScene, depth=0) =
  var
    mp = self.midpoint
    left = int(self.left)
    right = int(self.right)
  scene.app.display.setDrawColor(255, 255, 255, 255)
  for x in left..right:
    scene.app.display.drawPoint(x, mp)

  draw(self.backward, scene, depth+1)
  draw(self.forward, scene, depth+1)

method draw(self: Leaf[Pane], scene: GameScene, depth=0) =
  let
    margin = 5
    region = self.region
    left = region.left + margin
    right = region.right - margin
    top = region.top + margin
    bottom = region.bottom - margin
    color = extractRGB((if self.content.selected: FG else: BG) as colors.Color )
  scene.app.display.setDrawColor(color.r.uint8, color.g.uint8, color.b.uint8, 255.uint8)
  for y in top..bottom:
    for x in left..right:
      scene.app.display.drawPoint(x.cint, y.cint);

method draw(self: GameScene) =
  self.app.clear(0, 0, 0)
  self.bsp.root.draw(self)

method update(self: GameScene, t, dt: float) =
  let keys = getKeyboardState()
  var x, y: cint
  getMouseState(addr x, addr y)
  self.last = self.bsp.leafAtPoint(x / 4.0, y / 4.0)
  if not isNil(self.last):
    for leaf in self.bsp.leaves:
      leaf.content.selected = leaf == self.last

proc handle_key(self: GameScene, keysym: KeySym) =
  case keysym.sym:
    of K_D:
      if not isNil(self.last):
        self.bsp.delete(self.last)
    of K_I:
      var x, y: cint
      getMouseState(addr x, addr y)
      for node in self.bsp.leaves:
        if node.region.contains(cint(x.float / 4.0), cint(y.float / 4.0)):
          echo repr(node.region)
          echo "Parent: ", type(node.parent).name
    of K_V:
      if not isNil(self.last):
        var splitLeaf = self.bsp.vsplit((self.last as Leaf[Pane]), 0.5)
        splitLeaf.content = newPane()
        self.last = nil
    of K_H:
      if not isNil(self.last):
        var splitLeaf = self.bsp.hsplit((self.last as Leaf[Pane]), 0.5)
        splitLeaf.content = newPane()
        self.last = nil
    of K_R:
      self.bsp.root.resize(self.bsp.root.region)
    else: discard
  self.last = nil

method handle(self: GameScene, event: Event) =
  case event.kind:
    of KeyDown:
      self.handle_key(event.key.keysym)
    else: discard

let
  app = newApp("settings.json")
  scene = newGameScene(app)
  root = (scene.bsp.root as Leaf[Pane])

root.content = newPane()

scene.draw()
app.run(scene)
