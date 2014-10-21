
DomainEvent = Space.cqrs.DomainEvent

class Space.cqrs.AggregateRoot

  @toString: -> 'Space.cqrs.AggregateRoot'

  _id: null
  _version: 0
  _events: null
  _eventHandler: null

  # ============= PUBLIC ============ #

  @UID_REQUIRED_ERROR = "#{AggregateRoot}: AggregateRoot needs an UID on creation."
  @DOMAIN_EVENT_REQUIRED_ERROR = "#{AggregateRoot}: Event must inherit from Space.cqrs.DomainEvent"
  @CANNOT_HANDLE_EVENT_ERROR = "#{AggregateRoot}: Cannot handle event of type: "
  @INVALID_EVENT_SOURCE_ID_ERROR = "#{AggregateRoot}: The given event has an invalid source id."

  constructor: (id) ->

    unless id? then throw new Error AggregateRoot.UID_REQUIRED_ERROR

    @_id = id
    @_events = []
    @_eventHandler = {}

  getId: -> @_id

  getVersion: -> @_version

  getEvents: -> @_events

  mapEvents: ->

    events = Array.prototype.slice.call arguments

    if events.length % 2 != 0
      throw new Error "mapDomainEvents must take an even number of arguments."

    for type, index in events by 2
      @_eventHandler[type.toString()] = events[index+1]

  applyEvent: (event) ->
    @_handleEvent event
    @_appendEvent event

  replayEvent: (event) -> @_handleEvent event

  isHistory: (data) -> toString.call(data) == '[object Array]'

  loadHistory: (history) -> @replayEvent(event) for event in history

  # ============= PRIVATE ============ #

  _appendEvent: (event) -> @_events.push event

  _handleEvent: (event) ->

    unless event instanceof DomainEvent then throw new Error AggregateRoot.DOMAIN_EVENT_REQUIRED_ERROR
    unless event.sourceId is @_id then throw new Error AggregateRoot.INVALID_EVENT_SOURCE_ID_ERROR

    handler = @_eventHandler[event.type]
    unless handler? then throw new Error AggregateRoot.CANNOT_HANDLE_EVENT_ERROR + event.type
    handler.call this, event

    if event.version? then @_version = event.version
