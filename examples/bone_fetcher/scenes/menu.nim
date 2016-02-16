import sdl2
import sdl2/ttf

import dadren/application
import dadren/scenes
import dadren/tilepacks
import dadren/textures
import dadren/utils

import misc/bfutils

ttfInit()

type
  MenuScene = ref object of Scene
    app: App
    tilepack: Tilepack
    font: FontPtr

proc menuScene*(app: App): MenuScene =
  let
    render_size = app.getLogicalSize()
    camera_position = (0, 0)
    camera_size = render_size
    font = openFont("assets/OpenSans-Regular.ttf", 14)

  if font == nil:
    quit "Font is nil"

  new(result)
  result.app = app
  result.tilepack = app.resources.tilepacks.load("retrodays")
  result.font = font

method enter*(self: MenuScene) =
  discard

method leave*(self: MenuScene) =
  discard

method handle*(self: MenuScene, event: Event) =
  discard

method update*(self: MenuScene, t, dt: float) =
  let keys = getKeyboardState()

  if keys[SDL_SCANCODE_ESCAPE.cint]:
    system.quit()

method draw*(self: MenuScene) =
  var fg: Color = color(255, 0, 255, 255)
  var bg: Color = color(255, 255, 0, 255)
  var surface: SurfacePtr = renderText(self.font, "Play", fg, bg)
  var texturePtr: TexturePtr = self.app.display.loadTexture(surface)

  var dst: sdl2.Rect = (0.cint, 0.cint, 0.cint, 0.cint)

  sdl2.queryTexture(texturePtr, nil, nil, addr dst.w, addr dst.h)

  self.app.display.copy(texturePtr, cast[ptr sdl2.Rect](nil), dst.addr)
