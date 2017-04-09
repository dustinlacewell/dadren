import typetraits
import strutils
import random

import sdl2

import dadren.application
import dadren.scenes
import dadren.utils
import dadren.bsp

type
  Color = ref object
    r,g,b: int
  GameScene = ref object of Scene
    app: App
    bsp: BSPTree[Color]
    last: Leaf[Color]

proc newGameScene(app: App): GameScene =
  new(result)
  result.app = app
  let size = app.getLogicalSize()
  result.bsp = newBSPTree(Color(), 0f, 0f, size.w.float, size.h.float)

converter scancode2uint8(x: Scancode): cint = cint(x)
converter uint82bool(x: uint8):bool  = bool(x)

proc contains[T](self: utils.Region[T], x, y: float): bool =
  return  x > self.left and x < self.right and
          y > self.top and y < self.bottom

method toStr(x: BSPNode[Color], depth = 0): string {.base.} =
  "Override me!"

method toStr(x: VSplit[Color], depth = 0): string =
  result = ""
  for i in 0..depth:
    result = result & "-"

  result = result & "VSplit " & $(x.region.left) & ", " & $(x.region.top) & ", " & $(x.region.right) & ", " & $(x.region.bottom) & "\n"

  return result & x.backward.toStr(depth+1) & x.forward.toStr(depth+1)

method toStr(x: HSplit[Color], depth = 0): string =
  result = ""
  for i in 0..depth:
    result = result & "-"
  result = result & "HSplit " & $(x.region.left) & " & " & $(x.region.top) & " & " & $(x.region.right) & " & " & $(x.region.bottom) & "\n"

  return result & x.backward.toStr(depth+1) & x.forward.toStr(depth+1)

method toStr(x: Leaf[Color], depth = 0): string =
  result = ""
  for i in 0..depth:
    result = result & ":"
  return "$1 Leaf: Region(w:$2-$4, h:$3-$5) Color($6, $7, $8)\n" % [
    result,
    $(x.region.left), $(x.region.top), $(x.region.right), $(x.region.bottom),
    $(x.content.r), $(x.content.g), $(x.content.b)
  ]

method draw(self: BSPNode[Color], display: var RendererPtr, depth=0) {.base.} =
  echo "Override this!"

method draw(self: VSplit[Color], display: var RendererPtr, depth=0) =
  var
    mp = self.midpoint
    top = int(self.top)
    bottom = int(self.bottom)
  display.setDrawColor(255, 255, 255, 255)
  for y in top..bottom:
    display.drawPoint(mp, y)

  draw(self.backward, display, depth+1)
  draw(self.forward, display, depth+1)

method draw(self: HSplit[Color], display: var RendererPtr, depth=0) =
  var
    mp = self.midpoint
    left = int(self.left)
    right = int(self.right)
  display.setDrawColor(255, 255, 255, 255)
  for x in left..right:
    display.drawPoint(x, mp)

  draw(self.backward, display, depth+1)
  draw(self.forward, display, depth+1)

method draw(self: Leaf[Color], display: var RendererPtr, depth=0) =
  let
    margin = 5
    region = self.region
    left = region.left + margin
    right = region.right - margin
    top = region.top + margin
    bottom = region.bottom - margin
    color = self.content
  display.setDrawColor(color.r.uint8, color.g.uint8, color.b.uint8, 255.uint8)
  for y in top..bottom:
    for x in left..right:
      display.drawPoint(x.cint, y.cint);

method draw(self: GameScene) =
  self.app.clear(0, 0, 0)
  self.bsp.root.draw(self.app.display)

method update(self: GameScene, t, dt: float) =
  let keys = getKeyboardState()
  var x, y: cint
  getMouseState(addr x, addr y)
  for node in self.bsp.leaves:
    if node.region.contains(cint(x.float / 4.0), cint(y.float / 4.0)):
      self.last = node
      node.content = Color(r:255)
    else:
      node.content = Color(g:255)

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
    of K_F:
      echo self.bsp.root.toStr()
      for leaf in self.bsp.leaves:
        echo leaf.toStr()
    of K_V:
      if not isNil(self.last):
        var splitLeaf = self.bsp.vsplit((self.last as Leaf[Color]), 0.5)
        splitLeaf.content = Color(r:255)
        self.last = nil
    of K_H:
      if not isNil(self.last):
        var splitLeaf = self.bsp.hsplit((self.last as Leaf[Color]), 0.5)
        splitLeaf.content = Color(r:255)
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
  root = (scene.bsp.root as Leaf[Color])

root.content = Color(b:255)

scene.draw()
app.run(scene)
