class Space.eventSourcing.Router extends Space.messaging.Controller

  @type 'Space.eventSourcing.Router'

  @ERRORS: {

    aggregateNotSpecified: 'Please specify a Router::Aggregate class to be
    managed by the router.'

    missingInitializingCommand: 'Please specify Router::InitializingCommand (a command class)
    that will be used to create new instanes of the managed aggregate.'

    noAggregateFoundToHandleCommand: (command) ->
      new Error "No aggregate <#{command.targetId}> found to
                 handle #{command.typeName()}"
  }

  Dependencies: {
    repository: 'Space.eventSourcing.Repository'
    commitStore: 'Space.eventSourcing.CommitStore'
    log: 'Space.eventSourcing.Log'
  }

  Aggregate: null
  InitializingCommand: null
  RouteCommands: null

  constructor: ->
    if not @Aggregate?
      throw new Error Router.ERRORS.aggregateNotSpecified
    if not @InitializingCommand?
      throw new Error Router.ERRORS.missingInitializingCommand
    @RouteCommands ?= []
    super

  onDependenciesReady: ->
    super
    @commandBus.registerHandler @InitializingCommand, (cmd) =>
      @log "#{this}: Creating new #{@Aggregate} with command #{cmd.typeName()}\n", cmd
      @repository.save new @Aggregate(cmd)
    @_routeCommandToAggregate(commandType) for commandType in @RouteCommands

  _routeCommandToAggregate: (commandType) ->
    @commandBus.registerHandler commandType, @_genericCommandHandler

  _genericCommandHandler: (command) =>
    if not command? then return
    @log "#{this}: Handling command #{command.typeName()} for
          #{@Aggregate}<#{command.targetId}>\n", command
    aggregate = @repository.find @Aggregate, command.targetId
    if not aggregate?
      throw Router.ERRORS.noAggregateFoundToHandleCommand(command)
    aggregate.handle command
    @repository.save aggregate
