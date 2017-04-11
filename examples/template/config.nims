import ospaths

let
  path = thisDir()
  name = splitPath(path)[1]

switch("hints", "off")
switch("verbosity", "0")
switch("nimcache", ".nimcache")

task test, "test the example":
  switch("out", "bin/test")
  switch("r")
  setCommand("c", "test.nim")

task build, "build the example":
  switch("out", "bin" / name)
  setCommand("c", "main.nim")

task run, "run the example":
  switch("r")
  buildTask()




