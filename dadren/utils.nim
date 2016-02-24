import future
import sequtils
import tables
import unittest

import random

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


proc merge*[K, V](d1: var Table[K, V], d2: Table[K, V]) =
  for k, v in d2:
    d1[k] = v

