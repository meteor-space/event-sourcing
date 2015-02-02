
generateTypeNameMethod = (typeName) -> return -> typeName

generateFromJSONValueFunction = (Class, fields) ->
  return (json) ->

    fields = if Class.fields? then Class.fields() else null

    if fields?
      json[field] = EJSON.parse(json[field]) for field of fields when json[field]?

    new Class(json)

class Space.cqrs.Serializable

  @toString: -> 'Space.cqrs.Serializable'

  @type: (name, fields) ->

    Class = this
    if fields? then Class.fields = fields

    # overrides the fully qualified name of this class
    @toString = generateTypeNameMethod(name)

    # make it EJSON serializable
    Class::typeName = generateTypeNameMethod(name)
    EJSON.addType name, generateFromJSONValueFunction(Class, fields)

  constructor: (data) ->

    fields = @_getSerializableFields()
    if not fields? then return

    check data, fields

    # copy fields to instance
    @[key] = data[key] for key of fields

  toJSONValue: ->

    fields = @_getSerializableFields()

    # No special fields, simply parse instance to new object
    if not fields? then return JSON.parse JSON.stringify(this)

    # Fields defined, parse them through EJSON to support nested types
    serialized = {}
    serialized[key] = EJSON.stringify(@[key]) for key of fields when @[key]?

    return serialized

  _getSerializableFields: ->
    if @constructor.fields? then return @constructor.fields() else return null
