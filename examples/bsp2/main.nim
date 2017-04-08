import typetraits
import strutils
import random

import sdl2

import dadren.application
import dadren.scenes
import dadren.utils

template `as` (a, b: untyped): untyped = ((b)a)

type
  BSPNode[T] = ref object of RootObj
    parent: BSPNode[T]
    region: Region[float]
  ParentNode[T] = ref object of BSPNode[T]
    forward, backward: BSPNode[T]
    ratio: float
  Leaf[T]= ref object of BSPNode[T]
    content: T
  HSplit[T] = ref object of ParentNode[T]
  VSplit[T] = ref object of ParentNode[T]
  BSPTree[T] = ref object
    root: BSPNode[T]
    leaves: seq[Leaf[T]]

proc newLeaf[T](content: T, left, top, right, bottom: float, parent: BSPNode[T] = nil): Leaf[T] =
  result = new(Leaf[T])
  result.parent = parent
  result.content = content
  result.region = Region[T](left:left, top:top, right:right, bottom:bottom)

proc newBSPTree[T](content: T, left, top, right, bottom: float): BSPTree[T] =
  result = new(BSPTree[T])
  result.root = newLeaf(content, left, top, right, bottom)
  let l = result.root as Leaf[T]
  result.leaves = @[l]

method left[T](self: T): float = self.region.left
method top[T](self: T): float = self.region.top
method right[T](self: T): float = self.region.right
method bottom[T](self: T): float = self.region.bottom

method midpoint[T](self: ParentNode[T]): float =
  raise newException(Exception, "midpoint not implemented for ParentNode")

method midpoint[T](self: VSplit[T]): float =
  self.region.midpointW(self.ratio)

method midpoint[T](self: HSplit[T]): float =
  self.region.midpointH(self.ratio)

proc newSibling[T](self: VSplit[T], target: Leaf): Leaf =
  newLeaf[T](
    target.content,
    self.midpoint, target.region.top,
    target.region.right, target.region.bottom, self)

proc newSibling[T](self: HSplit[T], target: Leaf): Leaf =
  newLeaf[T](
    target.content,
    target.region.left, self.midpoint,
    target.region.right, target.region.bottom, self)

method siblingFor[T](self: ParentNode[T], target: Leaf): BSPNode[T] =
  if self.forward == target: self.backward else: self.forward


proc resize[T](self: Leaf[T], region: Region[float]) =
  self.region = region

proc resize[T](self: VSplit[T], region: Region[float]) =
  self.region = region
  let
    mp = self.midpoint
    bw = self.backward
    fw = self.forward
  bw.resize(Region[T](
    left:self.left,
    top:self.top,
    right:mp,
    bottom:self.bottom))
  fw.resize(Region[T](
    left:mp,
    top:self.top,
    right:self.right,
    bottom:self.bottom))

proc resize[T](self: HSplit[T], region: Region[float]) =
  self.region = region
  let
    mp = self.midpoint
    bw = self.backward
    fw = self.forward
  bw.resize(Region[T](
    left:self.left,
    top:self.top,
    right:self.right,
    bottom:mp))
  fw.resize(Region[T](
    left:self.left,
    top:mp,
    right:self.right,
    bottom:self.bottom))

proc adjust[T](self: T, ratio: float) =
  self.ratio = ratio
  resize(self, self.region)

proc split[T, K](self: BSPTree[T], target: Leaf, parent: K): Leaf[T] =
  # update the new parent
  parent.backward = target
  parent.forward = parent.newSibling(target)
  parent.resize(target.region)
  # track the new leaf
  self.leaves.add(parent.forward as Leaf)
  return (parent.forward as Leaf)

proc vsplit[T](self: BSPTree[T], target:Leaf, ratio: float): Leaf[T] =
  var parent = new(VSplit[T])
  parent.parent = target.parent
  parent.ratio = ratio
  result = self.split(target, parent)

proc hsplit[T](self: BSPTree[T], target:Leaf, ratio: float): Leaf[T] =
  var parent = new(HSplit[T])
  parent.parent = target.parent
  parent.ratio = ratio
  result = self.split(target, parent)

method delete[T](self: BSPTree[T], target:Leaf) =
  # return target if it is the root node
  echo "Attempting delete"
  if self.root == target:
    echo "Wont delete root."
    return

  let idx = self.leaves.find(target)
  if idx > -1:
    echo "Deleting target"
    self.leaves.delete(idx)
  var parent = (target.parent as ParentNode[T])

  # determine correct sibling
  var sib = parent.siblingFor(target)
  echo "Performing resize on result"
  echo $(target.region)
  echo $(sib.region)
  echo $(parent.region)
  sib.region = parent.region

  # if target's parent is root
  if self.root == target.parent:
    echo "Target's parent is root"
    self.root = sib
    return

  if isNil(parent.parent):
    echo "Grandparent is nil"
    return

  var grandparent = (parent.parent as ParentNode[T])

  # if target's parent is a split
  if parent == grandparent:
    grandparent.forward = sib
  else:
    grandparent.backward = sib

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

method toStr(x: BSPNode[Color], depth = 0): string =
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
    result = result & "+"
  return result & "Leaf " & $(x.region.left) & " & " & $(x.region.top) & " & " & $(x.region.right) & " & " & $(x.region.bottom) & "\n"

method draw(self: BSPNode[Color], display: var RendererPtr, depth=0) =
  echo "Override this!"

method draw(self: VSplit[Color], display: var RendererPtr, depth=0) =
  # var
  #   mp = self.midpointW(self.ratio)
  #   top = self.top
  #   bottom = self.bottom
  # display.setDrawColor(255, 255, 255, 255)
  # var y: int
  # for y in 0..10:
  #   echo "wtf"
  # echo "VSplit ", depth
  # echo "-- backward"
  draw(self.backward, display, depth+1)
  # echo "-- forward"
  draw(self.forward, display, depth+1)

method draw(self: HSplit[Color], display: var RendererPtr, depth=0) =
  # let mp = self.midpointH(self.ratio)
  # display.setDrawColor(255, 255, 255, 255)
  # for y in (self.region.top)..(self.region.bottom):
  #   display.drawPoint(x, mp)
  # echo "HSplit ", depth
  # echo "-- backward"
  draw(self.backward, display, depth+1)
  # echo "-- forward"
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
    of K_V:
      if not isNil(self.last):
        var splitLeaf = self.bsp.vsplit((self.last as Leaf[Color]), 0.5)
        splitLeaf.content = Color(r:255)
    of K_H:
      if not isNil(self.last):
        var splitLeaf = self.bsp.hsplit((self.last as Leaf[Color]), 0.5)
        splitLeaf.content = Color(r:255)
    else: discard

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
