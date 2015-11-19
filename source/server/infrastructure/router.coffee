class Space.eventSourcing.Router extends Space.messaging.Controller

  @type 'Space.eventSourcing.Router'

  @ERRORS: {

    aggregateNotSpecified: 'Please specify a Router::aggregate class to be
    managed by the router.'

    missingInitializingCommand: 'Please specify Router::initializingCommand (a command class)
    that will be used to create new instanes of the managed aggregate.'

    noAggregateFoundToHandleMessage: (message, id) ->
      new Error "No aggregate <#{id}> found to handle #{message.typeName()}"
  }

  dependencies: {
    repository: 'Space.eventSourcing.Repository'
    commitStore: 'Space.eventSourcing.CommitStore'
    log: 'Space.eventSourcing.Log'
  }

  aggregate: null
  initializingCommand: null
  routeCommands: null
  routeEvents: null
  eventCorrelationProperty: 'correlationId'

  constructor: ->
    if not @aggregate?
      throw new Error Router.ERRORS.aggregateNotSpecified
    if not @initializingCommand?
      throw new Error Router.ERRORS.missingInitializingCommand
    @routeCommands ?= []
    @routeEvents ?= []
    super

  onDependenciesReady: ->
    super
    @_setupInitializingCommand()
    @_routeCommandToAggregate(commandType) for commandType in @routeCommands
    @_routeEventToAggregate(eventType) for eventType in @routeEvents

  _setupInitializingCommand: ->
    @commandBus.registerHandler @initializingCommand, (cmd) =>
      @log "#{this}: Creating new #{@aggregate} with command #{cmd.typeName()}\n", cmd
      @repository.save new @aggregate(cmd)

  _routeCommandToAggregate: (commandType) ->
    @commandBus.registerHandler commandType, @_genericCommandHandler

  _routeEventToAggregate: (eventType) ->
    @eventBus.subscribeTo eventType, @_genericEventHandler

  _genericCommandHandler: (command) =>
    @log "#{this}: Handling command #{command.typeName()} for
          #{@aggregate}<#{command.targetId}>\n", command
    aggregate = @repository.find @aggregate, command.targetId
    throw Router.ERRORS.noAggregateFoundToHandleMessage(event) if !aggregate?
    @repository.save aggregate.handle(command)

  _genericEventHandler: (event) =>
    id = event[this.eventCorrelationProperty]
    return if not id?
    @log "#{this}: Handling event #{event.typeName()} for
          #{@aggregate}<#{id}>\n", event
    aggregate = @repository.find @aggregate, id
    throw Router.ERRORS.noAggregateFoundToHandleMessage(event) if !aggregate?
    @repository.save aggregate.handle(event)
