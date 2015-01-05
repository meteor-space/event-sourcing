
generateTypeNameMethod = (typeName) -> return -> typeName

class Space.cqrs.Serializable

  @toString: -> 'Space.cqrs.Serializable'

  @type: (name) ->

    Class = this

    # overrides the fully qualified name of this class
    @toString = generateTypeNameMethod(name)

    # make it EJSON serializable
    Class::typeName = generateTypeNameMethod(name)
    Class::toJSONValue = -> JSON.parse(JSON.stringify(this))
    Class::fromJSONValue = (json) => new Class(json)

    EJSON.addType name, Class::fromJSONValue

  @ERRORS:
    typeNameRequired: "#{Serializable}: you have to specify the EJSON type."

  constructor: ->
    if not @typeName? then throw new Error Serializable.ERRORS.typeNameRequired
