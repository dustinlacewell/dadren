import marshal

proc loadSettings*[T](filename: string): T =
  let json_data = readFile(filename)
  to[T](json_data)


