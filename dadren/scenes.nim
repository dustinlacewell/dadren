import sdl2


type
  Scene* = ref object of RootObj
    manager*: SceneManager

  SceneManagerObj = object
    current*: Scene
  SceneManager* = ref SceneManagerObj

method enter*(self: Scene) {.base.} =
  discard

method leave*(self: Scene) =
  discard

method handle*(self: Scene, event: Event) =
  discard

method update*(self: Scene, t, dt: float) =
  discard

method draw*(self: Scene) {.base.} =
  discard

proc set_scene*(sm: SceneManager, scene: Scene) =
  if sm.current != nil:
    sm.current.leave()
  sm.current = scene
  scene.manager = sm
  scene.enter()

proc newSceneManager*(first_scene: Scene = nil): SceneManager =
  new(result)
  if first_scene != nil:
    result.set_scene(first_scene)
