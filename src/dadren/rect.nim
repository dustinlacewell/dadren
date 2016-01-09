type
  Rect*[T] = object
    width*, height*: T
  IntRect* = Rect[int]

proc area[T](r: Rect[T]): T = r.width * r.height
