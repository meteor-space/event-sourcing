
class Space.cqrs.Event

  @toString: -> 'Space.cqrs.Event'

  @type: (value) ->
    this::type = value
    @toString = -> value

  @ERRORS:
    typeRequiredError: "#{Event}: event type is required."
    paramsRequiredError: "#{Event}: params are required."
    sourceIdRequired: "#{Event}: sourceId is required."

  type: null
  sourceId: null
  data: null
  version: null

  constructor: (params) ->

    if !@type? and !params.type? then throw new Error Event.ERRORS.typeRequiredError
    if not params? then throw new Error Event.ERRORS.paramsRequiredError
    if not params.sourceId? then throw new Error Event.ERRORS.sourceIdRequired

    @type ?= params.type
    @sourceId = params.sourceId
    @data = if params.data? then params.data else {}
    @version = if params.version? then params.version else null