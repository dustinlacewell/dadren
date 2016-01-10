import sdl2

import dadren/application
import dadren/atlases

type
  GameStateObj = object
    terrain: Atlas
  GameState = ref GameStateObj

proc newGameState(): GameState = new(result)

proc handleFrame(app: App, state: GameState, delta_t:float) =
  # draw the first tile in the atlas to 0, 0
  app.display.render(state.terrain, 0, 0, 0, 0)

proc handleEvents(app: App, state: GameState, event: Event) =
  discard

let
  app = newApp("settings.json")
  state = newGameState()

# load the terrain texture atlas into game state
state.terrain = app.resources.atlases.load(
  "terrain", "tilesets/retrodays/terrain.png", 20, 20)

run[GameState](app, state, handleFrame, handleEvents)
