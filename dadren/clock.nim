import future
import times
import os
import strutils

type
  ClockObj = object
    step: float
    total, current*, delta*: float
  Clock* = ref ClockObj

proc newClock*(step: float): Clock =
  new(result)
  result.step = step
  result.total = 0.0
  result.delta = 0.0
  result.current = epochTime()

proc tick*(clock: Clock) =
  let new_time = epochTime()
  clock.delta = new_time - clock.current
  clock.current = new_time

  if clock.delta < clock.step:
    sleep(int((clock.step - clock.delta) * 1000))
