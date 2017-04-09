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
    forward*: BSPNode[T]
    backward*: BSPNode[T]
    ratio*: float
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
  let leaf = result.root as Leaf[T]
  result.leaves = @[leaf]

# helper methods for accessing the underlying region extents
method left*[T](self: BSPNode[T]): float {.base.} = self.region.left
method top*[T](self: BSPNode[T]): float {.base.} = self.region.top
method right*[T](self: BSPNode[T]): float {.base.} = self.region.right
method bottom*[T](self: BSPNode[T]): float {.base.} = self.region.bottom

method midpoint*[T](self: ParentNode[T]): float {.base.} =
  raise newException(Exception, "midpoint not implemented for ParentNode")

method midpoint*[T](self: VSplit[T]): float =
  # returns the midpoint between left and right extents
  self.region.midpointW(self.ratio)

method midpoint*[T](self: HSplit[T]): float =
  # returns the midpoint between top and bottom extents
  self.region.midpointH(self.ratio)

proc newSibling[T](self: VSplit[T], target: Leaf[T]): Leaf[T] =
  # creates a half-width sibling for target with the same content
  newLeaf[T](
    target.content,
    self.midpoint, target.region.top,
    target.region.right, target.region.bottom, self)

proc newSibling[T](self: HSplit[T], target: Leaf[T]): Leaf[T] =
  # creates a half-height sibling for target with the same content
  newLeaf[T](
    target.content,
    target.region.left, self.midpoint,
    target.region.right, target.region.bottom, self)

method siblingFor*[T](self: ParentNode[T], target: Leaf[T]): BSPNode[T] {.base.} =
  # returns the sibling for the provided target
  if self.forward == target: self.backward else: self.forward

method resize*[T](self: BSPNode[T], region: Region[float]) {.base.} =
  self.region = region

method resize*[T](self: VSplit[T], region: Region[float]) =
  # set region and recursively resize children
  self.region = region
  let
    mp = self.midpoint
    bw = self.backward
    fw = self.forward
  resize(self.backward, Region[T](
    left:self.left,
    top:self.top,
    right:mp,
    bottom:self.bottom))
  fw.resize(Region[T](
    left:mp,
    top:self.top,
    right:self.right,
    bottom:self.bottom))

method resize*[T](self: HSplit[T], region: Region[float]) =
  # set region and recursively resize children
  self.region = region
  let
    mp = self.midpoint
    bw = self.backward
    fw = self.forward
  bw.resize(Region[T](
    left:self.left,
    top:self.top,
    right:self.right,
    bottom:mp))
  fw.resize(Region[T](
    left:self.left,
    top:mp,
    right:self.right,
    bottom:self.bottom))

method adjust*[T](self: ParentNode[T], ratio: float) {.base.} =
  # set the ratio and recursively resize all children
  self.ratio = ratio
  resize(self, self.region)

proc split[T, K](self: BSPTree[T], target: Leaf[T], parent: K): Leaf[T] =
  # replace target with parent, and add target and new sibling a children
  if not isNil(target.parent):
    # target's parent becomes grandparent
    var gp = (target.parent as ParentNode[T])
    # make sure parent is correct child of grandparent
    if gp.forward == target:
      gp.forward = parent
    else:
      gp.backward = parent

  # update tree's root node
  if self.root == target:
    self.root = parent

  # update the new parent
  parent.backward = target
  parent.backward.parent = parent
  parent.forward = parent.newSibling(target)
  parent.forward.parent = parent
  parent.resize(target.region)
  # track the new sibling leaf
  self.leaves.add(parent.forward as Leaf[T])
  # return newly created sibling
  return (parent.forward as Leaf[T])

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
  if idx > -1:
    self.leaves.delete(idx)

  # get target parent
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
