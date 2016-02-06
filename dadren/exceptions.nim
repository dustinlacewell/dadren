type
  DadrenError* = object of Exception # base Dadren exception
  ResourceError* = object of DadrenError # base resource exception
  InvalidResourceError* = object of ResourceError # resource failed to load
  NoSuchResourceError* = object of ResourceError # no such resource loaded
