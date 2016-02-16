#
## The application module contains the central type to the Dadren engine the `AppObj` and its Ref type `App`.

## The App serves a few primary roles for the game author:

## - Loading configuration and assets
## - Running the main loop
## - Calling user event handlers

## The App is initialized by passing the filename of a settings file which contains the needed information.

import os
import future
import strutils

import sdl2

import ./settings
import ./resources
import ./clock
import ./scenes
import ./utils

type
  AppSettings = object
    title*: string
    scale*: float
    vsync: bool
    accelerated: bool
    resolution*: Resolution
    tilepack_path*: string
  AppObj* = object
    settings*: AppSettings
    resources*: ResourceManager
    scenes*: SceneManager
    window*: WindowPtr
    display*: RendererPtr
    clock*: Clock
    running*: bool
  App* = ref AppObj

proc setLogicalSize(app: App, width, height: cint) =
  discard app.display.setLogicalSize(cint(width.float / app.settings.scale),
                                     cint(height.float / app.settings.scale))

proc setLogicalSize(app: App) =
  if app.settings.resolution.width == -1 and app.settings.resolution.height == -1:
    var dm = DisplayMode()
    discard getCurrentDisplayMode(0, dm)
    app.setLogicalSize(dm.w, dm.h)
  else:
    app.setLogicalSize(app.settings.resolution.width,
                       app.settings.resolution.height)

proc getLogicalSize*(app: App): Size =
  var width, height: cint
  app.display.getLogicalSize(width, height)
  (width.int, height.int)

proc getDisplayFlags(settings: AppSettings): cint =
  if settings.accelerated:
    result = result or Renderer_Accelerated
  else:
    result = result or Renderer_Software

  if settings.vsync:
    result = result or Renderer_PresentVsync

proc newApp*(settings_filename: string): App =
  sdl2.init(INIT_EVERYTHING)
  var dm = DisplayMode()
  discard getCurrentDisplayMode(0, dm)

  new(result)
  result.settings = loadSettings[AppSettings](settings_filename)

  let render_flags = result.settings.getDisplayFlags()

  result.clock = newClock(0.01666666 * 2.0)
  result.scenes = newSceneManager()
  result.window = createWindow(result.settings.title, 0, 0, dm.w, dm.h,
                               (SDL_WINDOW_SHOWN or
                                SDL_WINDOW_ALLOW_HIGHDPI or
                                SDL_WINDOW_RESIZABLE))
  result.display = createRenderer(result.window, -1, render_flags)
  result.resources = newResourceManager(result.window,
                                        result.display,
                                        result.settings.tilepack_path)
  result.setLogicalSize()
  result.running = true

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
          app.setLogicalSize(event.window.data1, event.window.data2)
      else:
        # call the user's event handler
        app.scenes.current.handle(event)

proc drawFrame(app: App) =
  # app.display.setRenderTarget(nil) # set window as render target
  # app.setLogicalSize() # configure the logical render size (output scaling)
  # app.clear(0, 0, 0)
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

