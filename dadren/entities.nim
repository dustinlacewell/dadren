import tables
import json
import marshal
import strutils

import ./magic

type
  Position* = object
    x*, y*: float

  Velocity* = object
    dx*, dy*: float

  Icon* = object
    rune*: string

aggregate(Entity, [Position, Velocity, Icon])

