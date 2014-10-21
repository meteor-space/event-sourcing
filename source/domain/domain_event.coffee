
class Space.cqrs.DomainEvent

  @toString: -> 'Space.cqrs.DomainEvent'

  @PARAMS_REQUIRED_ERROR = "#{DomainEvent}: Params are required."
  @EVENT_TYPE_REQUIRED_ERROR = "#{DomainEvent}: Domain event type is required."
  @SOURCE_ID_REQUIRED_ERROR = "#{DomainEvent}: Source ID is required."
  @DATA_REQUIRED_ERROR = "#{DomainEvent}: Data is required."

  type: null
  sourceId: null
  data: null
  version: null

  constructor: (params) ->

    if not params? then throw new Error DomainEvent.PARAMS_REQUIRED_ERROR
    if not params.type? then throw new Error DomainEvent.EVENT_TYPE_REQUIRED_ERROR
    if not params.sourceId? then throw new Error DomainEvent.SOURCE_ID_REQUIRED_ERROR

    @type = params.type.toString()
    @sourceId = params.sourceId
    @data = if params.data? then params.data else {}
    @version = if params.version? then params.version else 0