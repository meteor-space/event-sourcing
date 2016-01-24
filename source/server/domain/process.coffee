{Event, Command} = Space.domain

class Space.eventSourcing.Process extends Space.eventSourcing.Aggregate

  eventCorrelationProperty: null
  _commands: null

  @type 'Space.eventSourcing.Process'

  constructor: (id, data, isSnapshot) ->
    # This process is created from an event -> create new Guid
    if (id instanceof Event) then @_id = new Guid()
    # This aggregate is created from a command -> assign targetId
    else if (id instanceof Command) then @_id = id.targetId
    else @_id = id
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

  _validateEvent: (event) ->
    throw new Error(@ERRORS.domainEventRequired) unless event instanceof Event
