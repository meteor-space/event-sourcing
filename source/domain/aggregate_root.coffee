
Event = Space.cqrs.Event

class Space.cqrs.AggregateRoot

  _id: null
  _version: 0
  _events: null

  @toString: -> 'Space.cqrs.AggregateRoot'

  @ERRORS:
    uuidRequired: "#{AggregateRoot}: AggregateRoot needs an UID on creation."
    domainEventRequired: "#{AggregateRoot}: Event must inherit from Space.cqrs.Event"
    cannotHandleEvent: "#{AggregateRoot}: Cannot handle event of type: "
    invalidEventSourceId: "#{AggregateRoot}: The given event has an invalid source id."

  @handle: (eventType, handler) ->

    # create event handlers cache if it doesnt exist yet
    unless @_eventHandlers? then @_eventHandlers = {}

    @_eventHandlers[eventType.toString()] = handler

  constructor: (id, data) ->

    unless id? then throw new Error AggregateRoot.ERRORS.uuidRequired

    @_id = id
    @_events = []

    if @isHistory(data) then @replayHistory(data) else @initialize(id, data)

    return this

  initialize: ->

  getId: -> @_id

  getVersion: -> @_version

  getEvents: -> @_events

  record: (event) ->
    @_handleEvent event
    @_events.push event

  replay: (event) -> @_handleEvent event, this

  isHistory: (data) -> toString.call(data) == '[object Array]'

  replayHistory: (history) -> @replay(event) for event in history

  # ============= PRIVATE ============ #

  _getEventHandler: (event) ->
    if @constructor._eventHandlers? then @constructor._eventHandlers[event.type]

  _validateEvent: (event) ->

    unless event instanceof Event
      throw new Error AggregateRoot.ERRORS.domainEventRequired

    unless event.sourceId is @getId()
      throw new Error AggregateRoot.ERRORS.invalidEventSourceId

    unless @_getEventHandler(event)?
      throw new Error AggregateRoot.ERRORS.cannotHandleEvent + event.type

  _handleEvent: (event) ->

    @_validateEvent event

    handler = @_getEventHandler event
    handler.call this, event

    if event.version? then @_version = event.version
