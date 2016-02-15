import algorithm
import future
import tables

import random
import perlin

import dadren/chunks
import dadren/utils

proc getJitter(j: float): float = random.random(j) - (j / 2.0)

proc getNoise(n: Noise, x, y: int, scale=1.0, jitter=0.0): float =
  let
    nx = float(x) / scale
    ny = float(y) / scale
  n.perlin(nx, ny) + getJitter(jitter)

type
  GeneratorType* = enum
    gtSimple, gtNoise
  Generator*[T] = ref object
    case kind*: GeneratorType
      of gtSimple:
        simple_callback*: proc(x, y: int): T
      of gtNoise:
        noise_callback*: proc(x, y: int, noise: float): T

proc `()`*[T](gen: Generator[T], x, y: int, noise = -1.0): T =
  case gen.kind:
    of gtSimple:
      return gen.simple_callback(x, y)
    of gtNoise:
      return gen.noise_callback(x, y, noise)

proc SimpleGenerator*[T](cb: proc(x, y: int): T): Generator[T] =
  new(result)
  result.kind = gtSimple
  result.simple_callback = cb

proc NoiseGenerator*[T](cb: proc(x, y: int, noise: float): T): Generator[T] =
  new(result)
  result.kind = gtNoise
  result.noise_callback = cb

proc newStaticGenerator*[T](value: T): Generator[T] =
  SimpleGenerator() do (x, y: int)-> T: value

proc newRandomGenerator*[T](values: seq[Generator[T]]): Generator[T] =
  SimpleGenerator() do (x, y: int)-> T:
    var selection = values.randomChoice()
    selection(x, y)

proc newWeightedGenerator*[T](choices: seq[(int, Generator[T])]): Generator[T] =
  SimpleGenerator() do (x, y: int)-> T:
    var selection = choices.weighted_choice()
    selection(x, y)

proc newBitonalGenerator*[T](a, b: Generator[T], scale=1.0): Generator[T] =
  var noise = newNoise()

  SimpleGenerator() do (x, y: int)-> T:
    let n = perlin.simplex(noise, x.float * scale, y.float * scale)
    if n > 0.5:
      a(x, y)
    else:
      b(x, y)

proc newRangedGenerator*[T](ranges: seq[(int, Generator[T])],
                            scale=1.0, jitter=0.0, child=false): Generator[T] =

  let callback = proc(x, y: int, noise: float): T =
    let choice = ranges.weighted_selection(noise)
    choice(x, y, noise)

  if child == false:
    var noise = newNoise()
    SimpleGenerator() do (x, y: int)-> T:
      let
        ax = max(0, x)
        ay = max(0, y)
        n = getNoise(noise, ax, ay, scale, jitter)
      callback(x, y, n)
  else:
    NoiseGenerator(callback)


type Billow[T] = tuple[noise: Noise, gen: Generator[T]]

proc newBillowGenerator*[T](generators: seq[Generator[T]], scale=1.0, jitter=0.0): Generator[T] =
  var choices = newSeq[Billow[T]]()

  for gen in generators:
    choices.add((noise: newNoise(), gen: gen))

  SimpleGenerator() do (x, y: int)-> T:
    var
      map = initTable[float, Billow[T]]()
      values = newSeq[float]()

    for billow in choices:
      let value = billow.noise.getNoise(x, y, scale, jitter)
      map[value] = billow
      values.add(value)

    values.sort(cmp, Descending)
    let delta = values[0] - values[1]
    map[values[0]].gen(x, y, delta * 3.0)
