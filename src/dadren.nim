import sdl2

import dadren/settings
import dadren/application
import dadren/rect

type
  GameSettings = object
    title: string
    window_size: IntRect
  GameStateObj = object
    score: int
  GameState = ref GameStateObj

proc newGameState(): GameState =
  new(result)
  result.score = 0

proc handleFrame(app: App, state: GameState, delta_t:float) =
  discard nil

proc handleEvents(app: App, state: GameState, event: Event) =
  discard nil

let
  so = loadSettings[GameSettings]("settings.json")
  app = newApp("Dadren", IntRect(width:500, height:500))
  state = newGameState()

run[GameState](app, state, handleFrame, handleEvents)


