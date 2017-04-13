import sdl2
import random

import dadren.application
import dadren.scenes

type
  CellPattern = tuple[left, mid, right, output: bool]
  Ruleset = array[0..7, bool]

proc pattern2rule(pattern: CellPattern): int =
  if pattern.right:
    result += 1
  if pattern.mid:
    result += 2
  if pattern.left:
    result += 4

proc binDigits(x: BiggestInt, r: int): int =
  ## Calculates how many digits `x` has when each digit covers `r` bits.
  result = 1
  var y = x shr r
  while y > 0:
    y = y shr r
    inc(result)

proc toBin*(x: BiggestInt, len: Natural = 0): string =
  ## converts `x` into its binary representation. The resulting string is
  ## always `len` characters long. By default the length is determined
  ## automatically. No leading ``0b`` prefix is generated.
  var
    mask: BiggestInt = 1
    shift: BiggestInt = 0
    len = if len == 0: binDigits(x, 1) else: len
  result = newString(len)
  for j in countdown(len-1, 0):
    result[j] = chr(int((x and mask) shr shift) + ord('0'))
    shift = shift + 1
    mask = mask shl 1

proc MakeRuleset(number: uint8): Ruleset =
  for i in 0..7:
    result[i] = ((number shr i) and 1) == 1

type
  GameScene = ref object of Scene
    app: App
    buf: TexturePtr

proc newGameScene(app: App): GameScene =
  new(result)
  result.app = app
  result.buf = app.display.createTexture(
    app.window.getPixelFormat(), SDL_TEXTUREACCESS_TARGET, app.size.w.cint, app.size.h.cint)

# treat uint8 as bool
converter uint82bool(x: uint8):bool  = bool(x)
# native rects to c rects
converter intRect2cintRect(t: tuple[x:int,y:int,w:int,h:int]):
  sdl2.Rect = (t.x.cint, t.y.cint, t.w.cint,t.h.cint)

method update(self: GameScene, t, dt: float) =
  # continuous per-frame input handling
  let keys = getKeyboardState()

  if keys[SDL_SCANCODE_LEFT.cint]:
    discard
  elif keys[SDL_SCANCODE_RIGHT.cint]:
    discard
  if keys[SDL_SCANCODE_UP.cint]:
    discard
  elif keys[SDL_SCANCODE_DOWN.cint]:
    discard

proc handle_key(gs: GameScene, keysym: KeySym) =
  # event-based input handling
  case keysym.sym:
    of K_LEFT: discard
    of K_RIGHT: discard
    of K_UP: discard
    of K_DOwN: discard
    else: discard

method handle(self: GameScene, event: Event) =
  case event.kind:
    of KeyDown:
      self.handle_key(event.key.keysym)
    else: discard

method draw(self: GameScene) =
  self.app.display.setRenderTarget(self.buf)
  let size = self.app.getLogicalSize()
  self.app.display.setDrawColor(255, 0, 0, 255)

  for i in 0..size.w:
    if random(2) == 1:
      self.app.display.drawPoint(i.cint, self.app.size.h.cint)
  var
    source: Rect = (0, 1, size.w, size.h - 1)
    destination: Rect = (0, 0, size.w, size.h - 1)

  self.app.display.copy(self.buf, addr source, addr destination)
  self.app.display.setRenderTarget(nil)
  self.app.display.copy(self.buf, nil, addr destination)

let
  app = newApp("settings.json")
  scene = newGameScene(app)
  ruleset = MakeRuleset(30)

app.size = app.getLogicalSize()
app.run(scene)
