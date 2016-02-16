import dadren/application
import dadren/scenes
import dadren/tilepacks

import scenes/menu

let
  app = newApp("settings.json")
  scene = menuScene(app)

scene.draw()
app.run(scene)
