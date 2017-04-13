import sdl2
import random

import dadren.application
import dadren.scenes
import dadren.utils

type
  Universe* = seq[bool]
  Pattern* = tuple[left, mid, right: bool]
  Rule* = array[0..7, bool]

  CA1D = ref object
    rule: uint8
    universe: seq[bool]
    age: uint8

  GameScene = ref object of Scene
    app: App
    buf: TexturePtr
    sim: CA1D

# treat uint8 as bool
converter uint8_bool(x: uint8):bool  = x.bool
# native rects to c rects
converter intRect_cintRect(t: tuple[x:int,y:int,w:int,h:int]):
  sdl2.Rect = (t.x.cint, t.y.cint, t.w.cint,t.h.cint)

converter uint8_Rule(x: uint8): Rule =
  for i in 0..7:
    result[i] = ((x shr i) and 1) == 1

converter Rule_uint8(x: Rule): uint8 =
  for i in 0..7:
    if x[i]:
      result = result + uint8(1 shl i)

proc index(pattern: Pattern): int =
  if pattern.right:
    result += 1
  if pattern.mid:
    result += 2
  if pattern.left:
    result += 4

proc newCA1D(rule: uint8, universe: Universe): CA1D =
  new(result)
  result.rule = rule
  result.universe = universe

proc ruleset(self: CA1D): Rule = self.rule

proc size(self: CA1D): int = self.universe.len

proc leftCellFor(self: CA1D, i: int): bool =
  if i - 1 > 0: self.universe[i - 1]
  else: self.universe[self.size - 1]

proc rightCellFor(self: CA1D, i: int): bool =
  if i + 1 < self.size: self.universe[i + 1]
  else: self.universe[0]

proc step(self: CA1D): Universe =
  result = newSeq[bool](self.size)
  for i in 0..self.size - 1:
    let
      left = self.leftCellFor(i)
      mid = self.universe[i]
      right = self.rightCellFor(i)
      pattern = (left, mid, right)
    result[i] = self.rule.Rule[pattern.index]
  self.age += 1

proc randomize(self: CA1D) =
  # randomize the universe
  for i in 0.. <self.size:
    self.universe[i] = random(2) == 1

proc newRenderTexture(app: App): TexturePtr =
  let format = app.window.getPixelFormat()
  app.display.createTexture(format, SDL_TEXTUREACCESS_TARGET, app.size.w, app.size.h)

proc newGameScene(app: App): GameScene =
  new(result)
  result.app = app
  result.buf = app.newRenderTexture()
  result.sim = newCA1D(0, newSeq[bool](app.size.w))
  result.sim.randomize()

proc autoStep(self: GameScene) =
  if self.sim.age > 20:
    # auto step the ruleset number
    self.sim.age = 0
    self.sim.rule += 1
    self.sim.randomize()

proc keyUpdate(self: GameScene, keys: ptr array[0 .. SDL_NUM_SCANCODES.int, uint8]) =
  # continuous per-frame input handling
  if keys[SDL_SCANCODE_LEFT.cint]: discard
  elif keys[SDL_SCANCODE_RIGHT.cint]: discard
  if keys[SDL_SCANCODE_UP.cint]: discard
  elif keys[SDL_SCANCODE_DOWN.cint]: discard

method update(self: GameScene, t, dt: float) =
  # step the simulation
  self.sim.universe = self.sim.step()
  # auto step the ruleset number
  self.autoStep()
  # realtime key handling
  self.keyUpdate(getKeyboardState())

proc handleKey(self: GameScene, keysym: KeySym) =
  # event-based input handling
  case keysym.sym:
    of K_LEFT: discard
    of K_RIGHT: discard
    of K_UP: discard
    of K_DOWN: discard
    else: discard

method handle(self: GameScene, event: Event) =
  case event.kind:
    of KeyDown:
      self.handleKey(event.key.keysym)
    else: discard

proc startTextureRender(self: GameScene): Size =
  self.app.display.setRenderTarget(self.buf)
  self.app.getLogicalSize()

proc endTextureRender(self: GameScene, src, dst: ptr sdl2.Rect) =
  self.app.display.copy(self.buf, src, dst)
  self.app.display.setRenderTarget(nil)
  self.app.display.copy(self.buf, nil, dst)

method draw(self: GameScene) =
  let size = self.startTextureRender()

  self.app.display.setDrawColor(255, 0, 0, 255)

  for i in 0..self.sim.size - 1:
    if self.sim.universe[i]:
      self.app.display.drawPoint(i, self.app.size.h)

  var
    source: sdl2.Rect = (0, 1, size.w, size.h - 1)
    destination: sdl2.Rect = (0, 0, size.w, size.h - 1)

  self.endTextureRender(addr source, addr destination)

when not defined(SUT):
  let
    app = newApp("settings.json")
    scene = newGameScene(app)

  app.size = app.getLogicalSize()
  app.run(scene)
