
import future
import sequtils
import tables

import random
import sdl2, sdl2/image

import unittest

type
  Point* = tuple[x, y: int]
  Size* = tuple[w, h: int]
  Region* = tuple[x, y, w, h: int]
  Resolution* = object
    width*, height*: int

converter cint2int*(x: cint): int = x.int
converter int2cint*(x: int): cint = x.cint
converter uint2int*(x: uint): int = x.int
converter int2uint*(x: int): uint = x.uint

proc weighted_choice*[T](options: seq[(int, T)],
                         rng: var MersenneTwister = mersenneTwisterInst): T =
  ## Return a T from a seq[(int, T)] where the first item in each tuple specifies a
  ## relative likelyhood, or weight, of that item being selected.

  ## The weights of the choices are summed and a random value from zero to the sum
  ## is generated. To generate the value to return to the caller, each choice's
  ## weight is subtracted from the sum. When a choice's weight causes the sum to
  ## go below zero the choice is returned.

  if len(options) == 0:
    return nil

  var sum: int = 0
  for pair in options:
    sum += pair[0]

  var val = rng.randomInt(1, sum + 1)

  for pair in options:
    val -= pair[0]
    if val <= 0:
      return pair[1]

when isMainModule:
  suite "weighted_choice":
    setup:
      var rng = initMersenneTwister(0)

    test "equally weighted options":
      let options = @[(1, "A"), (1, "B")]
      var a_picks = 0
      for i in 0..100:
        if "A" == weighted_choice(options, rng):
          a_picks += 1

      let
        ratio = a_picks.float / 100.0
        margin = 0.5 - ratio
      check:
        margin < 0.07

    test "inequally weighted options":
      let options = @[(1, "A"), (2, "B")]
      var a_picks = 0
      for i in 0..100:
        if "A" == weighted_choice(options, rng):
          a_picks += 1

      let
        ratio = a_picks.float / 100.0
        margin = 0.25 - ratio
      check:
        margin < 0.07

    test "weightless options":
      let options = @[(0, "A"), (2, "B")]
      var a_picks = 0
      for i in 0..100:
        if "A" == weighted_choice(options, rng):
          a_picks += 1

      let ratio = a_picks.float / 100.0
      check:
        ratio == 0.0

    test "empty options":
      let options = newSeq[(int, string)]()
      check:
        cast[string](nil) == weighted_choice(options, rng)

proc weighted_selection*[T](options: seq[(int, T)], selection: float): T =
  ## Return a T from a seq[(int, T)] based on the input selection. The selection is
  ## a float between 0.0 and 1.0. To determine the option to return a sum of all
  ## option weights is created. The selection value is mapped to the range of
  ## zero to the sum and the associated option is returned.
  var sum = 0
  for pair in options:
    sum += pair[0]

  var scaled_selection = min(1.0, selection) * float(sum)

  for pair in options:
    scaled_selection -= float(pair[0])
    if scaled_selection <= 0:
      return pair[1]

when isMainModule:
  suite "weighted_selection":

    test "various selections return correct option":
      let options = @[(1, "A"), (1, "B")]
      check:
        "A" == weighted_selection(options, -0.1)
        "A" == weighted_selection(options, 0.0)
        "A" == weighted_selection(options, 0.5)
        "B" == weighted_selection(options, 0.51)
        "B" == weighted_selection(options, 1.0)
        "B" == weighted_selection(options, 1.1)

    test "empty options results in nil result":
      let options = newSeq[(int, string)]()
      check:
        cast[string](nil) == weighted_selection(options, 0.0)


proc merge*[K, V](d1: var Table[K, V], d2: Table[K, V]) =
  for k, v in d2:
    d1[k] = v

when isMainModule:
  suite "merge":
    setup:
      var base = toTable([(1, 1), (2, 2)])

    test "test dictionaries get merged":
      merge(base, toTable([(2, 4)]))

      check:
        base[1] == 1
        base[2] == 4

    test "test empty dictionary":
      merge(base, initTable[int, int]())

      check:
        base[1] == 1
        base[2] == 2
