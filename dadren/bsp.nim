import typetraits
import strutils
import random

import dadren.utils

type
  # node base-type
  BSPNode*[T] = ref object of RootObj
    parent*: BSPNode[T]
    region*: Region[float]
  # leaf node holds actual T content
  Leaf*[T]= ref object of BSPNode[T]
    content*: T
  # parents maintain two children and partition ratio
  ParentNode*[T] = ref object of BSPNode[T]
    ratio*: float
    forward*: BSPNode[T]
    backward*: BSPNode[T]
  # two subclasses to hold vertical and horizontal implementations
  HSplit*[T] = ref object of ParentNode[T]
  VSplit*[T] = ref object of ParentNode[T]
  # coordinating structure with cached access to leaves
  BSPTree*[T] = ref object
    root*: BSPNode[T]
    leaves*: seq[Leaf[T]]


proc newLeaf[T](content: T, left, top, right, bottom: float, parent: BSPNode[T] = nil): Leaf[T] =
  result = new(Leaf[T])
  result.parent = parent
  result.content = content
  result.region = Region[T](left:left, top:top, right:right, bottom:bottom)

proc newBSPTree*[T](content: T, left, top, right, bottom: float): BSPTree[T] =
  # creates a new tree with a leaf containing the provided content as the root
  result = new(BSPTree[T])
  result.root = newLeaf(content, left, top, right, bottom)
  result.leaves = @[result.root as Leaf[T]]

# helper methods for accessing the underlying region extents
method left*[T](self: BSPNode[T]): float {.base.} = self.region.left
method top*[T](self: BSPNode[T]): float {.base.} = self.region.top
method right*[T](self: BSPNode[T]): float {.base.} = self.region.right
method bottom*[T](self: BSPNode[T]): float {.base.} = self.region.bottom

proc midpoint*[T](self: VSplit[T]): float =
  # returns the midpoint between left and right extents
  self.region.midpointW(self.ratio)

proc midpoint*[T](self: HSplit[T]): float =
  # returns the midpoint between top and bottom extents
  self.region.midpointH(self.ratio)

proc siblingFor*[T](self: ParentNode[T], target: Leaf[T]): BSPNode[T] =
  # returns the sibling for the provided target
  if self.forward == target: self.backward else: self.forward

method newSibling[T](self: ParentNode[T], target: Leaf[T]): Leaf[T] {.base.} = discard

method newSibling[T](self: VSplit[T], target: Leaf[T]): Leaf[T] =
  # creates a half-width sibling for target with the same content
  newLeaf[T](
    target.content,
    self.midpoint, target.region.top,
    target.region.right, target.region.bottom, self)

method newSibling[T](self: HSplit[T], target: Leaf[T]): Leaf[T] =
  # creates a half-height sibling for target with the same content
  newLeaf[T](
    target.content,
    target.region.left, self.midpoint,
    target.region.right, target.region.bottom, self)

method resize*[T](self: BSPNode[T], region: Region[float]) {.base.} =
  self.region = region

method resize*[T](self: VSplit[T], region: Region[float]) =
  # set region and recursively resize children
  self.region = region
  let
    mp = self.midpoint
    bw = self.backward
    fw = self.forward
  bw.resize(Region[T](
    # right edge is set to the midpoint
    left:self.left, top:self.top, right:mp, bottom:self.bottom))
  fw.resize(Region[T](
    # left edge is set to the midpoint
    left:mp, top:self.top, right:self.right, bottom:self.bottom))

method resize*[T](self: HSplit[T], region: Region[float]) =
  # set region and recursively resize children
  self.region = region
  let
    mp = self.midpoint
    bw = self.backward
    fw = self.forward
  bw.resize(Region[T](
    # bottom edge is set to the midpoint
    left:self.left, top:self.top, right:self.right, bottom:mp))
  fw.resize(Region[T](
    # top edge is set to the midpoint
    left:self.left, top:mp, right:self.right, bottom:self.bottom))

method adjust*[T](self: ParentNode[T], ratio: float) {.base.} =
  # set the ratio and recursively resize all children
  self.ratio = ratio
  resize(self, self.region)

proc subjugate[T](self: BSPTree[T], parent: ParentNode[T], backward, forward: Leaf[T], grandparent: ParentNode[T] = nil) =
  # reparent forward and backward under parent, and parent under grandparent if provided
  if isNil(grandparent):
    # if there's no grandparent, parent must be root
    self.root = parent
  else:
    # make sure parent is correct child of grandparent
    if grandparent.forward == backward or grandparent.forward == forward:
      grandparent.forward = parent
    else:
      grandparent.backward = parent

  # update the parent-child associations
  parent.backward = backward
  parent.backward.parent = parent
  parent.forward = forward
  parent.forward.parent = parent
  # recursively resize all children
  parent.resize(parent.region)

proc split[T](self: BSPTree[T], target: Leaf[T], parent: ParentNode[T]): Leaf[T] =
  result = parent.newSibling(target)
  parent.region = target.region
  subjugate(self, parent, target, result, (target.parent as ParentNode[T]))
  self.leaves.add(result)

proc vsplit*[T](self: BSPTree[T], target:Leaf[T], ratio: float): Leaf[T] =
  # vertically split the provided leaf and return new sibling
  var parent = new(VSplit[T])
  parent.parent = target.parent
  parent.ratio = ratio
  result = self.split(target, parent)

proc hsplit*[T](self: BSPTree[T], target:Leaf[T], ratio: float): Leaf[T] =
  # horizontally split the provided leaf and return new sibling
  var parent = new(HSplit[T])
  parent.parent = target.parent
  parent.ratio = ratio
  self.split(target, parent)

proc delete*[T](self: BSPTree[T], target:Leaf[T]) =
  # return target if it is the root node
  if self.root == target:
    return

  # stop tracking deleted node
  let idx = self.leaves.find(target)
  self.leaves.delete(idx)

  var parent = (target.parent as ParentNode[T])
  # determine correct sibling
  var sib = parent.siblingFor(target)
  # resize sibling to parent region
  sib.region = parent.region

  if self.root == parent:
    # if target's parent is root then sibling is new root
    self.root = sib
    sib.parent = nil
  else:
    # otherwise there is a grandparent
    var grandparent = (parent.parent as ParentNode[T])
    # grandparent becomes parent
    sib.parent = grandparent

    # ensure sibling is reparented in the correct direction
    if grandparent.forward == (parent as BSPNode[T]):
      grandparent.forward = sib
    else:
      grandparent.backward = sib

  # we could be more smart but just resize the whole tree
  self.root.resize(self.root.region)

proc leafAtPoint*[T](self: BSPTree[T], x, y: float): Leaf[T] =
  if self.root.region.contains(x, y):
    var node = (self.root as BSPNode[T])
    while node of ParentNode[T]:
      var parent = (node as ParentNode[T])
      if parent.backward.region.contains(x, y):
        node = (parent.backward as BSPNode[T])
      else:
        node = (parent.forward as BSPNode[T])
    return (node as Leaf[T])
