import macros
import tables

type
  Name* = object
    value: string
    exported: bool
  TypeName* = object # denotes a plain named type with optional generics
    name: Name
    parameters: seq[TypeDesc]
  TypeDescKind = enum tdkNamed, tdkTuple
  TypeDesc* = object # denotes an existing named or tuple type
    is_ref: bool
    case kind: TypeDescKind
      of tdkNamed:
        type_name: TypeName
      of tdkTuple:
        identifiers: seq[Field]
  Field* = object # denotes an typed name
    name: Name
    type_desc: TypeDesc
  Identifier = object # denotes a parameter or other assignable name
    name: Name
    type_desc: ref TypeDesc
    default: ref NimNode
  DescKind = enum
    dkStruct, dkInherited, dkTuple, dkAlias, dkVariant, dkEnum
  Desc = object # denotes an object description (used in type definitions)
    case kind: DescKind
      of dkAlias: # type is a simple alias
        alias: TypeDesc
      of dkTuple: # type is a tuple
        tuple_fields: seq[Field]
      of dkStruct: # type is a full object type
        struct_fields: seq[Field]
      of dkInherited: # type is a inheriting object type
        inherits: TypeName
        own_fields: seq[Field]
      of dkVariant: # type is composed of variants
        discriminator: Field
        variants: Table[Name, seq[Field]]
      of dkEnum: # type is an enum
        values: seq[Name]
  TypeDef = object
    type_name: TypeName
    description: Desc
    is_ref: bool

## Constructors

# forward declaration
proc newTypeDesc*(type_name: TypeName, is_ref: bool = false): TypeDesc

proc newName*(value: string, exported: bool = false): Name =
  result.value = value
  result.exported = exported

proc newTypeName*(name: Name, parameters: seq[TypeDesc]): TypeName =
  result.name = name
  result.parameters = parameters

proc newTypeName*(name: Name, parameters: seq[TypeName]): TypeName =
  result.name = name
  result.parameters = newSeq[TypeDesc]()
  for param in parameters:
    result.parameters.add(newTypeDesc(param))

proc newTypeName*(name: Name): TypeName =
  newTypeName(name, newSeq[TypeDesc]())

proc newTypeName*(name: string): TypeName =
  newTypeName(newName(name))

proc newTypeDesc*(type_name: TypeName, is_ref: bool = false): TypeDesc =
  result.kind = tdkNamed
  result.is_ref = is_ref
  result.type_name = type_name

proc newTypeDesc*(type_name: string, is_ref: bool = false): TypeDesc =
  newTypeDesc(newTypeName(type_name), is_ref)

proc newTypeDesc*(identifiers: seq[Field], is_ref: bool = false): TypeDesc =
  result.kind = tdkTuple
  result.is_ref = is_ref
  result.identifiers = identifiers

proc newSeqDesc*(type_name: TypeName): TypeDesc =
  let new_type_name = newTypeName(newName("seq"), @[type_name])
  newTypeDesc(new_type_name)

proc newSeqDesc*(type_name: string): TypeDesc =
  newSeqDesc(newTypeName(type_name))

proc newField*(name: Name, type_desc: TypeDesc): Field =
  result.name = name
  result.type_desc = type_desc

proc newField*(name: string, type_name: string, is_ref: bool = false): Field =
  result.name = newName(name)
  result.type_desc = newTypeDesc(newTypeName(type_name), is_ref)

proc newIdentifier*(name: Name,
                    type_desc: ref TypeDesc = nil,
                    default: ref NimNode = nil): Identifier =
  result.name = name
  result.type_desc = type_desc
  result.default = default

proc newAliasDesc*(alias: TypeDesc): Desc =
  result.kind = dkAlias
  result.alias = alias

proc newTupleDesc*(fields: seq[Field]): Desc =
  result.kind = dkTuple
  result.tuple_fields = fields

proc newStructDesc*(fields: seq[Field]): Desc =
  result.kind = dkStruct
  result.struct_fields = fields

proc newInheritedDesc*(fields: seq[Field], inherits: TypeName): Desc =
  result.kind = dkInherited
  result.own_fields = fields
  result.inherits = inherits

proc newVariantDesc*(discriminator: Field,
                     variants: Table[Name, seq[Field]]): Desc =
  result.kind = dkVariant
  result.discriminator = discriminator
  result.variants = variants

proc newEnumDesc*(values: seq[Name]): Desc =
  result.kind = dkEnum
  result.values = values

proc newTypeDef*(type_name: TypeName, desc: Desc, is_ref: bool = false): TypeDef =
  result.type_name = type_name
  result.description = desc
  result.is_ref = is_ref

## Helpers

proc exported*(name: string): Name =
  newName(name, true)

converter toName*(s: string): Name = newName(s)

## Renderers

# foward declaration
proc render*(type_desc: TypeDesc): NimNode {.compileTime.}

proc render*(name: Name): NimNode {.compileTime.} =
  result = ident(name.value)
  if name.exported:
    result = postfix(result, "*")

proc render*(type_name: TypeName): NimNode {.compileTime.} =
  if len(type_name.parameters) == 0:
    return type_name.name.render

  result = newNimNode(nnkBracketExpr)
  result.add(render(type_name.name))
  for param in type_name.parameters:
    result.add(param.render)

proc asTuple*(type_name: TypeName): tuple[name, params:NimNode] {.compileTime.} =
  let name = type_name.name.render
  var
    params = newEmptyNode()
    idents = newNimNode(nnkIdentDefs)

  if len(type_name.parameters) > 0:
    params = newNimNode(nnkGenericParams)
    for param in type_name.parameters:
      idents.add(param.render)
    idents.add(newEmptyNode())
    idents.add(newEmptyNode())
    params.add(idents)

  return (name, params)

proc render*(field: Field): NimNode {.compileTime.} =
  newIdentDefs(field.name.render, field.type_desc.render)

proc render*(type_desc: TypeDesc): NimNode =
  case type_desc.kind:
    of tdkNamed:
      result = type_desc.type_name.render
    of tdkTuple:
      result = newNimNode(nnkTupleTy)
      for field in type_desc.identifiers:
        result.add(field.render)
  if type_desc.is_ref:
    result = newNimNode(nnkRefTy).add(result)

proc render*(identifier: Identifier): NimNode {.compileTime.} =
  var desc, default: NimNode
  if identifier.type_desc != nil:
    desc = identifier.type_desc[].render
  else:
    desc = newEmptyNode()
  if identifier.default != nil:
    default = identifier.default[]
  else:
    default = newEmptyNode()
  newIdentDefs(identifier.name.render, desc, default)

proc render*(desc: Desc): NimNode {.compileTime.} =
  case desc.kind:
    of dkAlias:
      result = desc.alias.render
    of dkTuple:
      result = newNimNode(nnkTupleTy)
      for field in desc.tuple_fields:
        result.add(field.render)
    of dkStruct:
      result = newNimNode(nnkObjectTy)
      result.add(newEmptyNode())
      result.add(newEmptyNode())
      var reclist = newNimNode(nnkRecList)
      for field in desc.struct_fields:
        reclist.add(field.render)
      result.add(reclist)
    of dkInherited:
      result = newNimNode(nnkObjectTy)
      result.add(newEmptyNode())
      var ofinherit = newNimNode(nnkOfInherit)
      ofinherit.add(desc.inherits.render)
      result.add(ofinherit)
      var reclist = newNimNode(nnkRecList)
      for field in desc.own_fields:
        reclist.add(field.render)
      result.add(reclist)
    of dkVariant:
      let msg = "I'm too lazy to implement variants :("
      raise newException(Exception, msg)
    of dkEnum:
      result = newNimNode(nnkEnumTy)
      result.add(newEmptyNode())
      for value in desc.values:
        result.add(ident(value.value))

proc render*(typedef: TypeDef): NimNode {.compileTime.} =
  result = newNimNode(nnkTypeDef)
  let (name, params) = typedef.type_name.asTuple()
  result.add(name)
  if len(params) > 0:
    echo params.treeRepr
    var generics = newNimNode(nnkGenericParams)
    for param in params:
      generics.add(param)
    result.add(generics)
  else:
    result.add(newEmptyNode())
  result.add(typedef.description.render)


