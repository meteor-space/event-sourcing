class Space.eventSourcing.Router extends Space.messaging.Controller

  @type 'Space.eventSourcing.Router'

  dependencies: {
    configuration: 'configuration'
    repository: 'Space.eventSourcing.Repository'
    commitStore: 'Space.eventSourcing.CommitStore'
    injector: 'Injector'
    log: 'log'
  }

  @ERRORS: {

    managedEventSourcableNotSpecified: 'Please specify a Router::eventSourceable
    class to be managed by the router.'

    missingInitializingMessage: 'Please specify Router::initializingMessage
    (an event or command class) that will be used to create new instanes of
    the managed eventSourceable.'

    missingEventCorrelationProperty: 'Please specify Process::eventCorrelationProperty
    that will be used to route events to the managed eventSourceable.'

    cannotHandleMessage: (message, id) ->
      new Error "No eventSourceable <#{id}> found to handle #{message.typeName()}"
  }

  eventSourceable: null
  initializingMessage: null
  routeEvents: null
  routeCommands: null
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
    super

  onDependenciesReady: ->
    super
    @_setupInitializingHandler()
    @_setupRehydratingHandlers()

  _setupInitializingHandler: ->
    if @initializingMessage.isSubclassOf(Space.domain.Event)
      @eventBus.subscribeTo(@initializingMessage, (event) =>
        # Only route events if the correlation property exists
        return unless aggregateId = message.meta? and message.meta[this.eventCorrelationProperty]
        instance = new @eventSourceable(aggregateId)
        @log.debug("#{this}: Created new #{@eventSourceable} with event}
                    #{event.typeName()}\n", event)
        @_routeMessage(instance, event, aggregateId)
      )
    else if @initializingMessage.isSubclassOf(Space.domain.Command)
      @commandBus.registerHandler(@initializingMessage, (command, callback) =>
        aggregateId = command.targetId
        instance = new @eventSourceable(aggregateId)
        @log.debug("#{this}: Created new #{@eventSourceable} with command}
                    #{command.typeName()}\n", command)
        @_routeMessage(instance, command, aggregateId, callback)
      )

  _setupRehydratingHandlers: ->
    @eventBus.subscribeTo(eventType, (event) =>
      # Only route events if the correlation property exists
      return unless aggregateId = event.meta? and event.meta[this.eventCorrelationProperty]
      @_loadInstanceAndRoute(aggregateId, event)
    ) for eventType in @routeEvents
    @commandBus.registerHandler(commandType, (command, callback) =>
      aggregateId = command.targetId
      @_loadInstanceAndRoute(aggregateId, command, callback)
    ) for commandType in @routeCommands

  _loadInstanceAndRoute: (aggregateId, message, callback) ->
    instance = @repository.find(@eventSourceable, aggregateId)
    throw Router.ERRORS.cannotHandleMessage(message) if !instance?
    @log.debug("#{this}: Rehydrated #{@eventSourceable} with #{message.typeName()}
                    #{message.typeName()}\n", message)
    @_routeMessage(instance, message, aggregateId, callback)

  _routeMessage: (instance, message, aggregateId, callback) =>
    try
      @injector.injectInto(instance)
      instance.handle(message)
      @repository.save(instance)
      callback?()
    catch error
      @_handleRoutingErrors(error, message, aggregateId, callback)

  _handleRoutingErrors: (error, message, aggregateId, callback) ->
    if error instanceof Space.eventSourcing.CommitConcurrencyException
      @_handleSaveError(error, message, aggregateId, callback)
    else if error instanceof Space.Error
      @log.error(@_logMsg(error.message))
      this.publish(new Space.domain.Exception({
        thrower: @eventSourceable.toString(),
        error: error
      }))
      callback?(error)
    else
      callback?(error)
      throw error

  _handleSaveError: (error, message, aggregateId, callback) ->
    @log.warning(@_logMsg("Re-handling message due to concurrency exception
            with message #{message.typeName()} for #{@eventSourceable}
            <#{aggregateId}>"), message)
    # Concurrency exceptions can often be resolved by simply re-handling the
    # message. This should be safe from endless loops, because if the
    # aggregate's state has since changed and the message is rejected,
    # a domain exception will be thrown, which is an application concern.
    @_loadInstanceAndRoute(aggregateId, message, callback)

  _logMsg: (message) -> "#{@configuration.appId}: #{this}: #{message}"
