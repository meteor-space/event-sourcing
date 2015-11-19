class Space.eventSourcing.AggregateRouter extends Space.messaging.Controller

  @type 'Space.eventSourcing.AggregateRouter'

  @ERRORS: {

    aggregateNotSpecified: 'Please specify a Router::aggregate class to be
    managed by the router.'

    missingInitializingCommand: 'Please specify Router::initializingCommand (a command class)
    that will be used to create new instanes of the managed aggregate.'

    noAggregateFoundToHandleCommand: (command) ->
      new Error "No aggregate <#{command.targetId}> found to handle #{command.typeName()}"
  }

  dependencies: {
    repository: 'Space.eventSourcing.Repository'
    commitStore: 'Space.eventSourcing.CommitStore'
    log: 'Space.eventSourcing.Log'
  }

  aggregate: null
  initializingCommand: null
  routeCommands: null

  constructor: ->
    if not @aggregate?
      throw new Error AggregateRouter.ERRORS.aggregateNotSpecified
    if not @initializingCommand?
      throw new Error AggregateRouter.ERRORS.missingInitializingCommand
    @routeCommands ?= []
    super

  onDependenciesReady: ->
    super
    @_setupInitializingCommand()
    @_routeCommandToAggregate(commandType) for commandType in @routeCommands

  _setupInitializingCommand: ->
    @commandBus.registerHandler @initializingCommand, (cmd) =>
      @log "#{this}: Creating new #{@aggregate} with command #{cmd.typeName()}\n", cmd
      @repository.save new @aggregate(cmd)

  _routeCommandToAggregate: (commandType) ->
    @commandBus.registerHandler commandType, @_genericCommandHandler

  _genericCommandHandler: (command) =>
    @log "#{this}: Handling command #{command.typeName()} for
          #{@aggregate}<#{command.targetId}>\n", command
    aggregate = @repository.find @aggregate, command.targetId
    throw AggregateRouter.ERRORS.noAggregateFoundToHandleCommand(command) if !aggregate?
    @repository.save aggregate.handle(command)
