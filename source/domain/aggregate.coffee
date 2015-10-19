
{Event, Command} = Space.messaging

class Space.eventSourcing.Aggregate extends Space.Object

  @type 'Space.eventSourcing.Aggregate'

  _id: null
  _version: 0
  _events: null
  _state: null
  _handlers: null

  # Override to define which custom properties this aggregate has
  FIELDS: {}

  ERRORS: {
    guidRequired: "#{Aggregate}: Aggregate needs an GUID on creation."
    domainEventRequired: "#{Aggregate}: Event must inherit from Space.messaging.Event"
    cannotHandleMessage: "#{Aggregate}: Cannot handle: "
    invalidEventSourceId: "#{Aggregate}: The given event has an invalid source id."
  }

  @createFromHistory: (events) -> new this(events[0].sourceId, events)

  @createFromSnapshot: (snapshot) -> new this(snapshot.id, snapshot, true)

  constructor: (id, data, isSnapshot) ->
    unless id? then throw new Error Aggregate::ERRORS.guidRequired
    # Initialize properties
    @_id = if (id instanceof Command) then id.targetId else id
    @_events = []
    @_handlers = {}
    # Apply default values for fields
    fields = @FIELDS
    (this[field] = fields[field]) for field of fields
    # Setup event and command handlers
    @_setupHandlers()
    # Bootstrap the aggregate
    if isSnapshot then @applySnapshot data
    else if @isHistory data then @replayHistory data
    else if (id instanceof Command) then @handle id
    else @initialize?.apply(this, arguments)
    return this

  getId: -> @_id

  getVersion: -> @_version

  getEvents: -> @_events

  getSnapshot: ->
    snapshot = {}
    snapshot.id = @_id
    snapshot.state = @_state
    snapshot.version = @_version
    (snapshot[field] = this[field]) for field of @FIELDS
    return snapshot

  applySnapshot: (snapshot) ->
    if not snapshot? then throw new Error "Invalid snapshot: #{snapshot}"
    @_id = snapshot.id
    @_state = snapshot.state
    @_version = snapshot.version
    (this[field] = snapshot[field]) for field of @FIELDS

  record: (event) ->
    @_validateEvent event
    @_events.push event
    @handle(event) if @hasHandlerFor(event)
    @_updateToEventVersion event

  replay: (event) ->
    @_validateEvent event
    @handle event if @hasHandlerFor(event)
    @_updateToEventVersion event

  isHistory: (data) -> toString.call(data) == '[object Array]'

  replayHistory: (history) -> @replay(event) for event in history

  handle: (message) -> @_getHandler(message).call this, message

  hasState: (state) -> if state? then @_state == state else @_state?

  getState: -> @_state

  hasHandlerFor: (message) -> @_handlers[message.typeName()]?

  # ============= PRIVATE ============ #

  _setupHandlers: ->
    @_handlers[messageType] = handler for messageType, handler of @handlers?()

  _getHandler: (message) ->
    if not @hasHandlerFor(message)
      throw new Error @ERRORS.cannotHandleMessage + message.typeName()
    else
      return @_handlers[message.typeName()]

  _validateEvent: (event) ->
    unless event instanceof Event
      throw new Error @ERRORS.domainEventRequired
    unless event.sourceId.toString() == @getId().toString()
      throw new Error @ERRORS.invalidEventSourceId

  _updateToEventVersion: (event) ->
    if event.version? then @_version = event.version
