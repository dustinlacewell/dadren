import unittest

include main

suite "ruleset converter":
  test "ruleset converter":
    check:
      255.uint8 == [true, true, true, true, true, true, true, true].Ruleset
