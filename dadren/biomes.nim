import algorithm
import future
import math
import sequtils
import tables
import os

import csfml
import perlin

randomize()

let scale = 25.0

proc getNoiseValue(n: Noise, x, y: int): float =
  let
    nx = float(x) / scale
    ny = float(y) / scale
  n.perlin(nx, ny)

type
  BiomeObj[T] = object
    noise: Noise
    generator: (float) -> T
  Biome[T] = ref BiomeObj[T]

proc newBiome[T](generator: (float) -> T): Biome[T] =
  new(result)
  result.noise = newNoise()
  result.generator = generator

proc getBiomeValue[T](biomes: seq[Biome[T]], x, y: int): T =
  var
    map = initTable[float, Biome[T]]()
    values = newSeq[float]()

  for biome in biomes:
    let value = getNoiseValue(biome.noise, x, y)
    map[value] = biome
    values.add(value)

  values.sort(cmp, Descending)
  let delta = values[0] - values[1]
  map[values[0]].generator(delta)

proc brighten(c: Color, amt: float): Color =
  var # scale up the components
    sr = float(c.r) * amt
    sg = float(c.g) * amt
    sb = float(c.b) * amt

  # clamp to 255 while still a float
  if sr > 255: sr = 255
  if sg > 255: sg = 255
  if sb > 255: sb = 255

  color(uint8 sr, uint8 sg, uint8 sb)

proc renderImage(size: tuple[w, h: int], pixelFunc: (int, int) -> Color): Image =
  # create image and set every pixel based on computed color
  result = newImage(cint size.w, cint size.h)
  for x in 0..size.w:
    for y in 0..size.h:
      let c = pixelFunc(x, y).brighten(4.0)
      result.setPixel(cint x, cint y, c)

proc handleEvents(window: RenderWindow) =
  var event: Event
  while window.pollEvent(event):
    let
      escape = event.kind == EventType.KeyPressed and event.key.code == KeyCode.Escape
      closed = event.kind == EventType.Closed
    if escape or closed:
      window.close()
  sleep(500)

let biomes = @[
  newBiome[Color]((d:float) => color(int 255 * d, 0, 0)),
  newBiome[Color]((d:float) => color(0, int 255 * d, 0)),
  newBiome[Color]((d:float) => color(0, 0, int 255 * d)),
  newBiome[Color]((d:float) => color(0, int 255 * d, int 255 * d)),
  newBiome[Color]((d:float) => color(int 255 * d, 0, int 255 * d)),
  newBiome[Color]((d:float) => color(int 255 * d, int 255 * d, 0)),
  newBiome[Color]((d:float) => color(int 255 * d, int 255 * d, int 255 * d)),
]

let
  title = "Demo of Biome Generation Using Noise"
  size = (w: 800, h: 600)
  mode = videoMode(cint size.w, cint size.h)
  window = newRenderWindow(mode, title)

  img = renderImage(size, (x, y) => getBiomeValue[Color](biomes, x, y))
  tex = newTexture(img, rect(0, 0, size.w, size.h))
  spr = newSprite(tex)

# save image to file
discard img.saveToFile("biomes.png")

# draw the sprite to the screen
window.draw(spr)

while window.open:
  window.display()
  handleEvents(window)
