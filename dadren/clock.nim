import future
import times
import strutils

type
  ClockObj = object
    total, current: float
    accumulator, step: float
  Clock* = ref ClockObj

proc newClock*(step: float): Clock =
  new(result)
  result.total = 0.0
  result.accumulator = 0.0
  result.current = epochTime()
  result.step = step

proc tick*(clock: Clock) =
  let
    new_time = epochTime()
    tick_time = new_time - clock.current
  clock.current = new_time
  clock.accumulator += tick_time

proc drain*(clock: Clock, handler: (float, float)->void) =
  while clock.accumulator >= clock.step:
    handler(clock.total, clock.step)
    clock.accumulator -= clock.step
    clock.total += clock.step
