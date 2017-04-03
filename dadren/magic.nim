import tables
import macros
import strutils
import json
import marshal

import ./meta

const MACRO_FORMAT_ERROR = "Improperly formatted invocation of `aggregate` macro. Check documentation for proper call syntax."

type MagicException = object of Exception

template throw (msg: string) =
  raise newException(MagicException, msg)

proc echo(node: NimNode) =
  echo node.treeRepr

proc to_object_name*(name: string): string = "$1Obj".format(name)

proc to_field_name*(name: string): string = name.toLowerAscii

proc to_table_name*(name: string): string = "t_$1".format(to_field_name(name))

proc to_enum_name*(name: string): string = "$1Type".format(name)

proc to_value_name*(a, b: string): string = "$1$2".format(a, b)

proc to_manager_name*(name: string): string = "$1Manager".format(name)

proc parse_component_names(node: NimNode): seq[string] =
  # Components passed to the `aggregate` macro must be specifed
  # either as `[A, List, Like, This]` or just a `SingleName`
  result = @[]
  case node.kind:
    of nnkIdent: # single identifier
      result.add($(node))
    of nnkBracket: # multiple identifiers in a bracket
      for child in node:
        if child.kind != nnkIdent:
          throw MACRO_FORMAT_ERROR
        result.add($(child))
    else: # anything else is invalid
      throw MACRO_FORMAT_ERROR

proc parse_aggregate_name(node: NimNode): string =
  # The name of the type to emit with the `aggregate` macro
  # should be specified as a simple identifier
  case node.kind:
    of nnkIdent:
      return $(node)
    else: throw MACRO_FORMAT_ERROR

proc generate_enum_type(name: string, values: seq[string]): NimNode {.compileTime.} =
  var value_names = newSeq[Name]()
  # create an Unknown enum for unknown component types
  value_names.add(to_value_name(name, "Unknown"))
  for value_name in values:
    value_names.add(to_value_name(name, value_name))

  let
    enum_name = to_enum_name(name)
    desc = newEnumDesc(value_names)
    type_name = newTypeName(enum_name, seq[TypeDesc](nil))
    type_def = newTypeDef(type_name, desc)

  type_def.render

proc generate_type(name: string, components: seq[string]): NimNode {.compileTime.} =
  var fields = newSeq[Field]()
  fields.add(
    newField(
      newName("id", true),
      newTypeDesc("int")))
  fields.add(
    newField(
      newName("manager", true),
      newTypeDesc(to_manager_name(name))))
  for component in components:
    let field_name = to_field_name(component)
    fields.add(
      newField(
        newName(field_name, true),
        newTypeDesc(component, true)))

  let
    desc = newStructDesc(fields)
    type_def = newTypeDef(newTypeName(newName(name, true)), desc)

  type_def.render

proc generate_manager_field(component: string): Field {.compileTime.} =
  let
    table_name = to_table_name(component)
    type_name = newTypeName("Table", @[
      newTypeDesc("int", false),
      newTypeDesc(component, true)])
    type_desc = newTypeDesc(type_name)
  newField(newName(table_name, true), type_desc)

proc generate_manager(name: string, components: seq[string]): NimNode {.compileTime.} =
  var fields = newSeq[Field]()
  fields.add(newField("last_id", "int"))
  fields.add(newField("entities", newSeqDesc("int")))
  fields.add(newField(newName("templates", true), newTypeDesc(newTypeName("Table", @[
    newTypeDesc("string", false),
    newTypeDesc("JsonNode", false)
  ]))))

  for component in components:
    fields.add(generate_manager_field(component))

  let
    desc = newStructDesc(fields)
    type_name = newName(to_object_name(to_manager_name(name)), true)
    type_def = newTypeDef(newTypeName(type_name), desc)

  type_def.render

proc generate_manager_ref(name: string): NimNode {.compileTime.} =
  let
    type_name = to_manager_name(name)
    desc = newAliasDesc(newTypeDesc(to_object_name(type_name), true))
    type_def = newTypeDef(newTypeName(newName(type_name, true)), desc)

  type_def.render

proc generate_cast(name: string, components: seq[string]): NimNode {.compileTime.} =
  var code = """
converter toEnum*(t: typedesc): $1 =
""".format(to_enum_name(name))
  for component in components:
    let snippet = """
  if t is $1: return $2
""".format(component, to_value_name(name, component))
    code = code & snippet
  parseStmt(code)[0]

proc generate_manager_init(name: string,
                           components: seq[string]): NimNode {.compileTime.} =
  var code = """
proc new$1*(): $1 =
  new(result)
  result.last_id = 0
  result.entities = @[]
  result.templates = initTable[string, JsonNode]()
""".format(to_manager_name(name))
  for component  in components:
    let snippet = """
  result.$3 = initTable[int, ref $2]()
""".format(to_field_name(component), component, to_table_name(component))
    code = code & snippet
  parseStmt(code)[0]

proc generate_get_entity(name: string,
                         components: seq[string]): NimNode {.compileTime.} =
  var code = """
proc get*(em: $1, id: int): $2 =
  if id notin em.entities:
    let msg = "Manager has no id: $3".format(id)
    raise newException(ValueError, msg)
  result.id = id
  result.manager = em
""".format(to_manager_name(name), name, "$1")
  for component in components:
    let snippet = """
  result.$1 = em.$2.getOrDefault(id)
""".format(to_field_name(component), to_table_name(component))
    code = code & snippet
  parseStmt(code)[0]

proc generate_has_component(name: string,
                            components: seq[string]): NimNode {.compileTime.} =
  var code = """
proc has*(em: $1, ctypes: varargs[$2, toEnum]): seq[$3] =
  result = @[]
  var entities = initTable[int, int]()
  for ctype in ctypes:
    case ctype:
""".format(to_manager_name(name), to_enum_name(name), name)
  for component in components:
    let snippet = """
    of $1:
      for id in em.$2.keys:
        entities[id] = entities.getOrDefault(id) + 1
""".format(to_value_name(name, component), to_table_name(component))
    code = code & snippet
  code = code & """
    else: discard
  for id, num in entities:
    if num == len(ctypes):
      result.add(em.get(id))"""
  parseStmt(code)[0]

proc generate_create_entity(name: string,
                            components: seq[string]): NimNode {.compileTime.} =
  var code = """
proc create*(em: var $1, tmpl: string): $2 =
  result = em.create()
  let named_tmpl = em.get(tmpl)
  for name, component in named_tmpl:
    case name:
""".format(to_manager_name(name), name)
  for component in components:
    let snippet = """
      of "$1":
        result.$2 = new(ref $1)
        result.$2[] = to[$1]($$(component))
        em.$3[result.id] = result.$2
""".format(component, to_field_name(component), to_table_name(component))
    code = code & snippet
  code = code & """
      else:
        let msg = "Template $1 refers to missing component type: $2".format(tmpl, name)
        raise newException(ValueError, msg)
"""
  parseStmt(code)[0]

proc generate_manager_boilerplate(name: string): NimNode {.compileTime.} =
  parseStmt("""
proc contains*(em: var $1, id: int): bool = id in em.entities
proc contains*(em: var $1, tmpl: string): bool = tmpl in em.templates

proc get*(em: $1, tmpl: string): JsonNode =
  if tmpl notin em.templates:
    let msg = "Manager has no template: $$1".format(tmpl)
    raise newException(ValueError, msg)
  return em.templates[tmpl]

proc add*(em: var $1, name: string, components: JsonNode) =
  if name in em:
    let msg = "Manager already has template with name: $$1".format(name)
    raise newException(ValueError, msg)
  em.templates[name] = components

proc load*(em: var $1, json_objs: JsonNode) =
  for name, components in json_objs:
    em.add(name, components)

proc load*(em: var $1, filename: string) =
  let
    json_data = readFile(filename)
    json_objs = parseJson(json_data)
  em.load(json_objs)

iterator items*(em: $1): Entity =
  for id in em.entities:
    yield em.get(id)

proc create*(em: var $1): Entity =
  em.last_id += 1
  result.id = em.last_id
  result.manager = em
  em.entities.add(result.id)

""".format(to_manager_name(name)))

proc generate_contains_enum(name: string,
                            components: seq[string]): NimNode {.compileTime.} =
  var code = """
proc contains_enum(e: $1, ctype: $2): bool =
  case ctype:
""".format(name, to_enum_name(name))
  for component in components:
    let snippet = """
    of $1: e.$2 != nil
""".format(to_value_name(name, component), to_field_name(component))
    code = code & snippet
  code = code & """
    else: false
"""
  parseStmt(code)[0]

proc generate_entity_boilerplate(name: string): NimNode {.compileTime.} =
  parseStmt("""
proc contains*(e: $1, ctype: typedesc): bool = e.contains_enum(toEnum(ctype))
proc contains*(e: $1, ctypes: varargs[$2, toEnum]): bool =
  result = true
  for ctype in ctypes:
    if not e.containsEnum(ctype):
      return false
""".format(name, to_enum_name(name)))

proc generate_add_component(name, component: string): NimNode {.compileTime.} =
  parseStmt("""
  proc add*(e: var $1, c: $2) =
  e.$3 = new(ref $2)
  e.$3[] = c
  e.manager.$4[e.id] = e.$3
  """.format(name, component, to_field_name(component), to_table_name(component)))[0]

proc generate_del_component(name: string,
                            components: seq[string]): NimNode {.compileTime.} =
  var code = """
proc del*(e: var $1, ctype: typedesc) =
  case toEnum(ctype):
""".format(name)
  for component in components:
    let snippet = """
    of $1$2:
      e.manager.$4.del(e.id)
      e.$3 = nil
""".format(name, component, to_field_name(component), to_table_name(component))
    code = code & snippet
  code = code & """
    else: discard
"""
  parseStmt(code)[0]

proc generate_type_section(name: string,
                           components: seq[string]): NimNode {.compileTime.} =
  result = newNimNode(nnkTypeSection)
  result.add(generate_enum_type(name, components))
  result.add(generate_type(name, components))
  result.add(generate_manager(name, components))
  result.add(generate_manager_ref(name))

macro aggregate*(type_name, component_list): untyped =
  let name = parse_aggregate_name(type_name)
  let components = parse_component_names(component_list)
  result = newNimNode(nnkStmtList)
  result.add(generate_type_section(name, components))
  result.add(generate_cast(name, components))
  result.add(generate_manager_init(name, components))
  result.add(generate_get_entity(name, components))
  result.add(generate_contains_enum(name, components))
  result.add(generate_has_component(name, components))
  result.add(generate_del_component(name, components))
  for child in generate_manager_boilerplate(name):
    result.add(child)
  for child in generate_entity_boilerplate(name):
    result.add(child)
  for component in components:
    result.add(generate_add_component(name, component))
  result.add(generate_create_entity(name, components))
