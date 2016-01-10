import sdl2

import dadren/application
import dadren/tilesets

type
  GameStateObj = object
    tileset: Tileset
  GameState = ref GameStateObj

proc newGameState(): GameState = new(result)

proc handleFrame(app: App, state: GameState, delta_t:float) =
  # draw the first tile in the atlas to 0, 0
  app.display.render(state.tileset, "maple", 0, 0)

proc handleEvents(app: App, state: GameState, event: Event) =
  discard

let
  app = newApp("settings.json")
  state = newGameState()

# load the terrain texture atlas into game state
state.tileset = app.resources.tilesets.load("retrodays")

run[GameState](app, state, handleFrame, handleEvents)
