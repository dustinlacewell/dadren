import unittest

include main

type
  sLeaf = Leaf[string]
  sHSplit = HSplit[string]
  sVSplit = VSplit[string]

suite "bsp tree":
  setup:
    var
      content = "Hello World"
      bsp = newBSPTree(content, 0, 0, 100, 100)
      root = (bsp.root as sLeaf)

  test "creation":
    check:
      bsp.root of sLeaf
      isNil(root.parent)
      root.region.left == 0
      root.region.top == 0
      root.region.right == 100
      root.region.bottom == 100
      root in bsp.leaves
      root.content == content

  test "horizontal split":
    var
      sib = bsp.hsplit(root, 0.5)
      split = (bsp.root as sHSplit)

    check:
      bsp.root == sib.parent
      sib.parent of sHSplit
      sib == (split.forward as sLeaf)
      root == (split.backward as sLeaf)
      root.region.top == 0
      root.region.bottom == 50
      sib.region.top == 50
      sib.region.bottom == 100
      sib in bsp.leaves
      root in bsp.leaves

  test "vertical split":
    var
      sib = bsp.vsplit(root, 0.5)
      split = (bsp.root as sVSplit)

    check:
      bsp.root == sib.parent
      sib.parent of sVSplit
      sib == (split.forward as sLeaf)
      root == (split.backward as sLeaf)
      root.region.left == 0
      root.region.right == 50
      sib.region.left == 50
      sib.region.right == 100
      sib in bsp.leaves
      root in bsp.leaves


  test "deletion":
    var
      sib = bsp.vsplit(root, 0.5)
      split = (bsp.root as sVSplit)
    bsp.delete(root)

    check:
      bsp.root == split.forward
