
class Space.cqrs.Event extends Space.cqrs.Serializable

  @toString: -> 'Space.cqrs.Event'

  @ERRORS:
    paramsRequiredError: "#{Event}: params are required."
    sourceIdRequired: "#{Event}: sourceId is required."

  sourceId: null
  data: null
  version: null

  constructor: (params) ->

    super()

    if not params? then throw new Error Event.ERRORS.paramsRequiredError
    if not params.sourceId? then throw new Error Event.ERRORS.sourceIdRequired

    @sourceId = params.sourceId
    @data = if params.data? then params.data else {}
    @version = if params.version? then params.version else null
