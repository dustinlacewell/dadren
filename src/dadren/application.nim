import os
import future

import sdl2, sdl2/image

import dadren/settings
import dadren/resources
import dadren/viewport
import dadren/utils

type
  AppSettings = object
    title: string
    resolution: Resolution
    tileset_path: string
  AppObj* = object
    settings: AppSettings
    resources*: ResourceManager
    window*: WindowPtr
    display*: RendererPtr
    running*: bool
  App* = ref AppObj

proc newApp*(settings_filename: string): App =
  sdl2.init(INIT_EVERYTHING)
  new(result)
  result.settings = loadSettings[AppSettings](settings_filename)
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

proc handleFrame[T](app: App, state: T, handler: (App, T, float)->void) =
  # set window as render target
  app.display.setRenderTarget(nil)
  # configure the logical render size (output scaling)
  app.setLogicalSize()
  # clear the display
  app.clear(0, 0, 0)
  # calculate frame time in seconds
  let dt = 1.0 # TODO
  # call the user's frame handler
  handler(app, state, dt)
  # display the frame result
  app.display.present

proc handleEvents[T](app: App, state: T, handler: (App, T, Event)->void) =
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
        handler(app, state, event)


proc run*[T](app: App, state: T,
             frame_handler: (App, T, float)->void,
             event_handler: (App, T, Event)->void) =

  while app.running:
    # call the user's frame and event handlers
    handleFrame[T](app, state, frame_handler)
    handleEvents[T](app, state, event_handler)
    # TODO throttle fps

  # clean up
  destroy app.resources
  destroy app.display
  destroy app.window
  sdl2.quit()

