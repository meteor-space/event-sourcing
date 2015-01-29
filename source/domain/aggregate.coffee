
Event = Space.cqrs.Event

class Space.cqrs.Aggregate

  _id: null
  _version: 0
  _events: null

  @toString: -> 'Space.cqrs.Aggregate'

  @ERRORS:
    guidRequired: "#{Aggregate}: Aggregate needs an GUID on creation."
    domainEventRequired: "#{Aggregate}: Event must inherit from Space.cqrs.Event"
    cannotHandleEvent: "#{Aggregate}: Cannot handle event of type: "
    invalidEventSourceId: "#{Aggregate}: The given event has an invalid source id."

  @handle: (eventType, handler) ->
    # create event handlers cache if it doesnt exist yet
    unless @_eventHandlers? then @_eventHandlers = {}
    @_eventHandlers[eventType.toString()] = handler

  constructor: (id, data) ->

    unless id? then throw new Error Aggregate.ERRORS.guidRequired
    @_id = id
    @_events = []
    if @isHistory(data) then @replayHistory(data) else @initialize(id, data)
    return this

  initialize: ->

  getId: -> @_id

  getVersion: -> @_version

  getEvents: -> @_events

  record: (event) ->
    @handle event
    @_events.push event
    @_updateToEventVersion event

  replay: (event) ->
    @handle event
    @_updateToEventVersion event

  isHistory: (data) -> toString.call(data) == '[object Array]'

  replayHistory: (history) -> @replay(event) for event in history

  handle: (event) ->
    @_validateEvent event
    handler = @_getEventHandler event
    handler.call this, event

  # ============= PRIVATE ============ #

  _getEventHandler: (event) ->
    if @constructor._eventHandlers? then @constructor._eventHandlers[event.typeName()]

  _validateEvent: (event) ->

    unless event instanceof Event
      throw new Error Aggregate.ERRORS.domainEventRequired

    unless @_getEventHandler(event)?
      throw new Error Aggregate.ERRORS.cannotHandleEvent + event.typeName()

  _updateToEventVersion: (event) ->
    if event.version? then @_version = event.version
