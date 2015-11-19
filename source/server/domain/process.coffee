{Event, Command} = Space.messaging

class Space.eventSourcing.Process extends Space.eventSourcing.Aggregate

  eventCorrelationProperty: null
  _commands: null

  @toString: -> 'Space.eventSourcing.Process'

  constructor: (id, data, isSnapshot) ->
    # This process is created from an event -> create new Guid
    @_id = if (id instanceof Event) then new Guid() else id
    # This aggregate is created from a command -> assign targetId
    @_id = if (id instanceof Command) then id.targetId else id
    @_events = []
    @_commands = []
    @_handlers = {}
    # Setup event and command handlers
    @_setupHandlers()
    # Bootstrap the aggregate
    if isSnapshot then @applySnapshot data
    else if @isHistory data then @replayHistory data
    else if (id instanceof Event) or (id instanceof Command) then @handle id
    else @initialize?.apply(this, arguments)
    return this

  trigger: (command) ->
    command.meta ?= {}
    command.meta[this.eventCorrelationProperty] = this.getId()
    @_commands.push command

  getCommands: -> @_commands

  handle: (message) ->
    @_getHandler(message).call this, message
    return this

  _validateEvent: (event) ->
    throw new Error(@ERRORS.domainEventRequired) unless event instanceof Event
