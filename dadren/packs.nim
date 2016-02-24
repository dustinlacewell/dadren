## Overview
## ========
## To make it easier to load many assets at once, this module exports a proc **loadPack** which can take the filename of a so-called **Packfile**, JSON formatted files that look like this:

## .. code-block:: nimrod
##    {
##      "includes": [
##        "other_pack.json",
##        "subdir/second_pack.json"
##      ],
##      "assets": {
##        "some_asset": {
##          "name": "Some Asset",
##          "description": "Some asset used for example",
##          "filename": "assets/some_asset.ext",
##        },
##        "other_asset": {
##          "name": "Some Other Asset",
##          "description": "Some other asset",
##          "filename": "assets/other_asset.ext",
##        }
##      }
##    }

##
## **"includes"** *optional*
##
## The "includes" field specifies an array of relative paths to other packfiles whose contents should be included in this one.

##
## **"assets"** *required*
##
## The "assets" field is specified as an object. Each field of the object names a different asset. Each asset is returned as is, that is as a JsonNode. Assets declared under the "assets" field will override assets in any included packfiles.

## Once loaded with **loadPack**, a single **ResourcePack** value will be returned containing a single Table mapping resource names to raw JsonNode assets. In the above example the assets are simple strings but they could be an integer, an array or even nested objects. It is up to consumers of ResourcePacks to deal with the resulting JsonNodes.

import tables
import json
import strutils

from ./utils import merge

type
  ResourcePack* = Table[string, JsonNode]
  ## Used to hold a table of JSON assets

proc newRecursivePackError(filename, duplicate: string): ref ValueError =
  let msg = "PackFile `$1` demands already seen include: $2"
  newException(ValueError, msg.format(filename, duplicate))

proc toTable(node: JsonNode): ResourcePack =
  if node.kind != JObject:
    let msg = "ResourcePack must be specified as JSON node."
    raise newException(ValueError, msg)

  var t = initTable[string, JsonNode]()
  for field in node.getFields():
    t[field.key] = field.val

  cast[ResourcePack](t)

proc loadPackFile(filename: string,
                  seen_includes: var seq[string]): JsonNode =
  if filename in seen_includes:
    raise newRecursivePackError(filename, filename)

  seen_includes.add(filename)

  let text = readFile(filename)
  result = parseJson(text)

  if result.kind != JObject:
    let msg = "PackFile `$1` not defined as JSON object."
    raise newException(ValueError, msg.format(filename))

proc parsePackData(pack_data: JsonNode,
                   filename: string,
                   seen_includes: var seq[string]): Table[string, JsonNode]

proc parseIncludesData(includes: JsonNode,
                       filename: string,
                       seen_includes: var seq[string]): Table[string, JsonNode] =

  if includes.kind != JArray:
    let msg = "PackFile `$1` has non-arry `includes` key."
    raise newException(ValueError, msg.format(filename))

  result = initTable[string, JsonNode]()

  for included_packfile in includes:
    if included_packfile.kind != JString:
      let msg = "PackFile `$1` includes non-string item."
      raise newException(ValueError, msg.format(filename))

    let
      pack_data = loadPackFile(included_packfile.getStr, seen_includes)
      included_assets = parsePackData(pack_data,
                                      included_packfile.getStr,
                                      seen_includes)
    result.merge(included_assets)

proc parsePackData(pack_data: JsonNode,
                   filename: string,
                   seen_includes: var seq[string]): Table[string, JsonNode] =

  result = initTable[string, JsonNode]()

  if pack_data.hasKey("includes"):
    let
      includes = pack_data["includes"]
      included_assets = parseIncludesData(includes, filename, seen_includes)
    result.merge(included_assets)

  if pack_data.hasKey("assets"):
    let
      assets = pack_data["assets"]
      pack_assets = toTable(assets)

    result.merge(pack_assets)

proc loadPack*(filename: string): ResourcePack =
  ## Loads the resource-pack at the provided filename (and recursively, any included
  ## resource-packs) and returns a flat table mapping resource names to JsonNodes.
  ##
  ## It is up to consumers of resource-packs to deal with the handling of various
  ## resources as they appear in the JSON.
  var seen_includes = newSeq[string]()
  let pack_data = loadPackFile(filename, seen_includes)
  parsePackData(pack_data, filename, seen_includes)
