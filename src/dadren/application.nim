import os
import future

import sdl2, sdl2/gfx

import dadren/rect

type
  AppObj* = object
    size*: IntRect
    fps: FpsManager
    window*: WindowPtr
    display*: RendererPtr
    running*: bool
  App* = ref AppObj

converter toCInt(x: int): cint = cint x

proc newApp*(title: string, size: IntRect): App =
  sdl2.init(INIT_EVERYTHING)
  new(result)
  result.size = size
  result.window = createWindow(title,
                               100, 100,
                               size.width, size.height,
                               SDL_WINDOW_SHOWN)
  result.display = createRenderer(result.window, -1,
                                  (Renderer_Accelerated or
                                   Renderer_PresentVsync or
                                   Renderer_TargetTexture))
  result.fps.init
  result.running = true


proc run*[T](app: App, state: T,
             frame_handler: (App, T, float)->void,
             event_handler: (App, T, Event)->void) =
  while app.running:
    # clear the window
    app.display.setDrawColor(0, 0, 0, 255)
    app.display.clear

    # call the user's frame handler
    let dt = app.fps.getFramerate() / 1000
    frame_handler(app, state, dt)

    # display the frame result
    app.display.present
    var event = defaultEvent

    # poll for any pending events
    while pollEvent(event):
      if event.kind == QuitEvent:
        app.running = false
        break
      # call the user's event handler
      event_handler(app, state, event)
    app.fps.delay

  destroy app.display
  destroy app.window

