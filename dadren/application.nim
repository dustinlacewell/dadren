import os
import future

import sdl2

import dadren/settings
import dadren/resources
import dadren/clock
import dadren/scenes
import dadren/utils

type
  AppSettings = object
    title*: string
    resolution*: Resolution
    tileset_path*: string
  AppObj* = object
    settings*: AppSettings
    resources*: ResourceManager
    scenes*: SceneManager
    window*: WindowPtr
    display*: RendererPtr
    clock*: Clock
    running*: bool
  App* = ref AppObj

proc newApp*(settings_filename: string): App =
  sdl2.init(INIT_EVERYTHING)
  new(result)
  result.settings = loadSettings[AppSettings](settings_filename)
  result.clock = newClock(0.01666666)
  result.scenes = newSceneManager()
  result.window = createWindow(result.settings.title, 0, 0,
                               result.settings.resolution.width,
                               result.settings.resolution.height,
                               (SDL_WINDOW_SHOWN or
                                SDL_WINDOW_ALLOW_HIGHDPI or
                                SDL_WINDOW_RESIZABLE))
  result.display = createRenderer(result.window, -1,
                                  (Renderer_Accelerated or
                                   Renderer_PresentVsync or
                                   Renderer_TargetTexture))
  result.resources = newResourceManager(result.window,
                                        result.display,
                                        result.settings.tileset_path)
  result.running = true

proc setLogicalSize(app: App, width, height: cint) =
  discard app.display.setLogicalSize(width, height)

proc setLogicalSize(app: App) =
  app.setLogicalSize(app.settings.resolution.width, app.settings.resolution.height)

proc clear*(app: App, r, g, b: uint8) =
  app.display.setDrawColor(r, g, b, 0)
  app.display.clear

proc updateFrame(app: App) =
  app.clock.tick()
  app.clock.drain((t: float, dt: float) => app.scenes.current.update(t, dt))

proc handleEvents(app: App) =
    var event = defaultEvent
    # poll for any pending events
    while pollEvent(event):
      case event.kind
      of QuitEvent:
        app.running = false
        break
      of WindowEvent:
        if event.window.event == WindowEvent_Resized:
          echo "resize: " & $event.window.data1 & " x " & $event.window.data2
      else:
        # call the user's event handler
        app.scenes.current.handle(event)

proc drawFrame(app: App) =
  app.display.setRenderTarget(nil) # set window as render target
  app.setLogicalSize() # configure the logical render size (output scaling)
  app.clear(0, 0, 0)
  app.scenes.current.draw()
  app.display.present

proc run*(app: App, first_scene: Scene) =
  app.scenes.set_scene(first_scene)

  while app.running:
    app.updateFrame()
    app.handleEvents()
    app.drawFrame()

  # clean up
  destroy app.resources
  destroy app.display
  destroy app.window
  sdl2.quit()

