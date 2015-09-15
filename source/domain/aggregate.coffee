
Event = Space.messaging.Event
Command = Space.messaging.Command

class Space.eventSourcing.Aggregate extends Space.Object

  _id: null
  _version: 0
  _events: null
  _state: null

  @toString: -> 'Space.eventSourcing.Aggregate'

  # Override to define which custom properties this aggregate has
  @FIELDS: {}

  @ERRORS:
    guidRequired: "#{Aggregate}: Aggregate needs an GUID on creation."
    domainEventRequired: "#{Aggregate}: Event must inherit from Space.messaging.Event"
    cannotHandleMessage: "#{Aggregate}: Cannot handle: "
    invalidEventSourceId: "#{Aggregate}: The given event has an invalid source id."

  @createFromHistory: (events) -> new this(events[0].sourceId, events)

  @createFromSnapshot: (snapshot) -> new this(snapshot.id, snapshot, true)

  @handle: (Type, handler) ->
    # create event handlers cache if it doesnt exist yet
    unless @_handlers? then @_handlers = {}
    @_handlers[Type.toString()] = handler

  @on: -> @handle.apply this, arguments

  constructor: (id, data, isSnapshot) ->
    unless id? then throw new Error Aggregate.ERRORS.guidRequired
    @_id = if (id instanceof Command) then id.targetId else id
    @_events = []
    fields = @constructor.FIELDS
    (this[field] = fields[field]) for field of fields
    if isSnapshot
      @applySnapshot data
    else if @isHistory data
      @replayHistory data
    else
      @initialize.apply(this, arguments)
    return this

  initialize: ->

  getId: -> @_id

  getVersion: -> @_version

  getEvents: -> @_events

  getSnapshot: ->
    snapshot = {}
    snapshot.id = @_id
    snapshot.state = @_state
    snapshot.version = @_version
    (snapshot[field] = this[field]) for field of @constructor.FIELDS
    return snapshot

  applySnapshot: (snapshot) ->
    if not snapshot? then throw new Error "Invalid snapshot: #{snapshot}"
    @_id = snapshot.id
    @_state = snapshot.state
    @_version = snapshot.version
    (this[field] = snapshot[field]) for field of @constructor.FIELDS

  record: (event) ->
    @_validateEvent event
    @_events.push event
    @handle event
    @_updateToEventVersion event

  replay: (event) ->
    @_validateEvent event
    @handle event
    @_updateToEventVersion event

  isHistory: (data) -> toString.call(data) == '[object Array]'

  replayHistory: (history) -> @replay(event) for event in history

  handle: (message) ->
    handler = @_getHandler message
    handler.call this, message

  hasState: (state) -> if state? then @_state == state else @_state?

  getState: -> @_state

  # ============= PRIVATE ============ #

  _getHandler: (message) ->
    handlers = @constructor._handlers
    if !handlers? or !handlers[message.typeName()]
      throw new Error Aggregate.ERRORS.cannotHandleMessage + message.typeName()
    else
      return handlers[message.typeName()]

  _validateEvent: (event) ->

    unless event instanceof Event
      throw new Error Aggregate.ERRORS.domainEventRequired

    unless event.sourceId.toString() == @getId().toString()
      throw new Error Aggregate.ERRORS.invalidEventSourceId

  _updateToEventVersion: (event) ->
    if event.version? then @_version = event.version
