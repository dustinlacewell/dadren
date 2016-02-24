import unittest

include ../dadren/utils

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
