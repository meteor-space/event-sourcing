class Space.eventSourcing.Router extends Space.messaging.Controller

  @ERRORS: {
    aggregateNotSpecified: 'Please specify a Router::Aggregate class to be
    managed by the router.'
    missingInitializingCommand: 'Please specify Router::InitializingCommand (a command class)
    that will be used to create new instanes of the managed aggregate.'
  }

  Dependencies: {
    repository: 'Space.eventSourcing.Repository'
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
    @constructor.handle @InitializingCommand, (cmd) =>
      @repository.save new @Aggregate(cmd)
    @_routeCommandToAggregate(commandType) for commandType in @RouteCommands
    super

  @mapEvent: (eventType, commandGenerator) ->
    @on eventType, (event) ->
      @_genericCommandHandler commandGenerator.call(this, event)

  _routeCommandToAggregate: (commandType) ->
    @constructor.handle commandType, @_genericCommandHandler

  _genericCommandHandler: (command) ->
    aggregate = @repository.find @Aggregate, command.targetId
    aggregate.handle command
    @repository.save aggregate
