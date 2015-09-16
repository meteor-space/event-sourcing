class Space.eventSourcing.Router extends Space.messaging.Controller

  @ERRORS: {
    aggregateNotSpecified: 'Please specify a Router::Aggregate class to be
    managed by the router.'
    missingCreateCommand: 'Please specify Router::CreateWith (a command class)
    that will be used to create new instanes of the managed aggregate.'
  }

  Dependencies: {
    repository: 'Space.eventSourcing.Repository'
  }

  Aggregate: null
  CreateWith: null

  constructor: ->
    if not @Aggregate? then throw new Error Router.ERRORS.aggregateNotSpecified
    if not @CreateWith? then throw new Error Router.ERRORS.missingCreateCommand
    super
    @_eventToCommandGeneratorMap = {}

  onDependenciesReady: ->
    @constructor.handle @CreateWith, (cmd) => @repository.save new @Aggregate(cmd)
    @_routeCommandToAggregate(commandType) for commandType in @RouteCommands
    super

  @mapEvent: (eventType, commandGenerator) ->
    @on eventType, (event) -> @_genericCommandHandler commandGenerator(event)

  _routeCommandToAggregate: (commandType) ->
    @constructor.handle commandType, @_genericCommandHandler

  _genericCommandHandler: (command) ->
    aggregate = @repository.find @Aggregate, command.targetId
    aggregate.handle command
    @repository.save aggregate
