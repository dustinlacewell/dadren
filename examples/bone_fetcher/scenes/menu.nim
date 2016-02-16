import sdl2
import sdl2/ttf

import dadren/application
import dadren/scenes
import dadren/tilepacks
import dadren/textures
import dadren/utils

import misc/bfutils

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
  var color: Color = color(255, 255, 255, 255)
  var surface: SurfacePtr = renderText(self.font, "Play", color, color)
  var texturePtr: TexturePtr = self.app.display.loadTexture(surface)

  var dst: sdl2.Rect = (0.cint,
                        0.cint,
                        200.cint,
                        50.cint)

  self.app.display.copy(texturePtr, cast[ptr sdl2.Rect](nil), dst.addr)

  #self.app.display.render(self.tilepack, "mature_alder", 5, 5)
