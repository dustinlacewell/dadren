import sdl2

import dadren/settings
import dadren/application
import dadren/atlases
import dadren/textures
import dadren/rect


type
  GameStateObj = object
    score: int
  GameState = ref GameStateObj

proc newGameState(): GameState =
  new(result)
  result.score = 0

proc handleFrame(app: App, state: GameState, delta_t:float) =
  let terrain = app.atlases.get("terrain")
  app.display.render(terrain.texture, 0, 0)

proc handleEvents(app: App, state: GameState, event: Event) =
  discard nil

let
  app = newApp("settings.json")
  state = newGameState()
  info = AtlasInfo(name:"terrain", width:20, height:20,
                   filename:"tilesets/retrodays/terrain.png")
  terrain_atlas = app.atlases.load(info)
run[GameState](app, state, handleFrame, handleEvents)
