import sdl2

import dadren.application
import dadren.scenes

type
  GameScene = ref object of Scene
    app: App

proc newGameScene(app: App): GameScene =
  new(result)
  result.app = app

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
  self.app.display.setDrawColor(255, 0, 0, 255)
  var r: sdl2.Rect = (10, 10, 10, 10)
  self.app.display.drawRect(addr r)

let
  app = newApp("settings.json")
  scene = newGameScene(app)

scene.draw()
app.run(scene)
