class Space.eventSourcing.Router extends Space.Object
  @type 'Space.eventSourcing.Router'

  @mixin [
    Space.messaging.CommandHandling
    Space.messaging.EventSubscribing
    Space.messaging.EventPublishing
  ]

  _commandHandlers: {}

  dependencies: {
    repository: 'Space.eventSourcing.Repository'
    injector: 'Injector'
    configuration: 'configuration'
    commandBus: 'Space.messaging.CommandBus'
    eventBus: 'Space.messaging.EventBus'
    log: 'log'
  }

  ERRORS: {
    managedEventSourcableNotSpecified: 'Please specify a Router::eventSourceable
    class to be managed by the router.'

    missingInitializingMessage: 'Please specify Router::initializingMessage
    (an event or command class) that will be used to create new instances of
    the managed eventSourceable.'

    missingEventCorrelationProperty: 'Please specify Process::eventCorrelationProperty
    that will be used to route events to the managed eventSourceable.'

    cannotHandleMessage: (message, id) ->
      new Error "No eventSourceable <#{id}> found to handle #{message.typeName()}"
  }

  eventSourceable: null
  initializingMessage: null
  routeCommands: null
  routeEvents: null
  eventCorrelationProperty: null

  constructor: ->
    if not @eventSourceable?
      throw new Error Router.ERRORS.managedEventSourcableNotSpecified
    if not @initializingMessage?
      throw new Error Router.ERRORS.missingInitializingMessage
    @routeEvents ?= []
    @eventCorrelationProperty = @eventSourceable::eventCorrelationProperty
    if @routeEvents.length > 0 and not @eventCorrelationProperty?
      throw new Error Router.ERRORS.missingEventCorrelationProperty
    @routeCommands ?= []

  onDependenciesReady: ->
    @_setupInitializingMessage()
    @_routeEventToEventSourceable(eventType) for eventType in @routeEvents
    @_routeCommandToEventSourceable(commandType) for commandType in @routeCommands

  _setupInitializingMessage: ->
    if @initializingMessage.isSubclassOf(Space.messaging.Event)
      @_initializingMessageEventHandler(@initializingMessage)
    else if @initializingMessage.isSubclassOf(Space.messaging.Command)
      @_initializingMessageCommandHandler(@initializingMessage)

  _initializingMessageEventHandler: (event) ->
    @eventBus.subscribeTo event, (cmd) =>
      @log.info("#{this}: Creating new #{@eventSourceable} with event
                #{event.typeName()}\n", event)

      eventSourceable = @_handleDomainErrors(->
        instance = new @eventSourceable(event.sourceId)
        @_injectDependencies(instance)
        instance.handle(event)
        return instance
      )
      @repository.save(eventSourceable) if eventSourceable?

  _initializingMessageCommandHandler: (command) ->
    @commandBus.registerHandler command, (cmd) =>
      @log.info("#{this}: Creating new #{@eventSourceable} with command
                #{cmd.typeName()}\n", cmd)

      eventSourceable = @_handleDomainErrors(->
        instance = new @eventSourceable(cmd.targetId)
        @_injectDependencies(instance)
        instance.handle(cmd)
        return instance
      )
      @repository.save(eventSourceable) if eventSourceable?

  _genericEventHandler: (event) =>
    # Only route this event if the correlation property exists
    unless event.meta? and event.meta[this.eventCorrelationProperty]?
      return

    correlationId = event.meta[@eventCorrelationProperty]
    @log.info(@_logMsg("Handling event #{event.typeName()} for
                       #{@eventSourceable}<#{correlationId}>\n"), event)

    eventSourceable = @repository.find(@eventSourceable, correlationId)
    unless eventSourceable?
      throw Router.ERRORS.cannotHandleMessage(event)

    @_injectDependencies(eventSourceable)
    eventSourceable = @_handleDomainErrors(->
      eventSourceable.handle event
    )
    @repository.save(eventSourceable) if eventSourceable?

  _genericCommandHandler: (command) =>
    if not command?
      return

    @log.info(@_logMsg("Handling command #{command.typeName()} for
                       #{@eventSourceable}<#{command.targetId}>"), command)

    eventSourceable = @repository.find @eventSourceable, command.targetId
    unless eventSourceable?
      throw Router.ERRORS.cannotHandleMessage(command)

    @_injectDependencies(eventSourceable)
    eventSourceable = @_handleDomainErrors(->
      eventSourceable.handle(command)
    )
    @repository.save(eventSourceable) if eventSourceable?

  _routeEventToEventSourceable: (eventType) ->
    @eventBus.subscribeTo eventType, @_genericEventHandler

  _routeCommandToEventSourceable: (commandType) ->
    @commandBus.registerHandler commandType, @_genericCommandHandler


  _injectDependencies: (eventSourceable) ->
    @injector.injectInto(eventSourceable)

  _logMsg: (message) -> "#{@configuration.appId}: #{this}: #{message}"

  _handleDomainErrors: (fn) ->
    try
      return fn.call(@)
    catch error
      if error instanceof Space.Error
        @publish(new Space.domain.Exception({
          thrower: @eventSourceable.toString(),
          error: error
        }))
        return null
      else
        throw error