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
    @_setupEventSubscriptions(eventType) for eventType in @routeEvents
    @_setupCommandHandlers(commandType) for commandType in @routeCommands

  _setupInitializingHandler: ->
    if @initializingMessage.isSubclassOf(Space.domain.Event)
      messageBus = @eventBus
      handlerSubscriber = @eventBus.subscribeTo
      idProperty = 'sourceId'
    else if @initializingMessage.isSubclassOf(Space.domain.Command)
      messageBus = @commandBus
      handlerSubscriber = @commandBus.registerHandler
      idProperty = 'targetId'
    handlerSubscriber.call(messageBus, @initializingMessage, (message) =>
      @log.debug("#{this}: Creating new #{@eventSourceable} with message
                  #{message.typeName()}\n", message)
      eventSourceable = @_handleDomainErrors(->
        instance = new @eventSourceable(message[idProperty])
        @injector.injectInto(instance)
        instance.handle(message)
        return instance
      )
      @repository.save(eventSourceable) if eventSourceable?
    )

  _setupEventSubscriptions: (eventType) ->
    @eventBus.subscribeTo eventType, @_genericHandler

  _setupCommandHandlers: (commandType) ->
    @commandBus.registerHandler commandType, @_genericHandler

  _genericHandler: (message) =>
    if message instanceof Space.domain.Command
      aggregateId = message.targetId
    if message instanceof Space.domain.Event
      # Only route this event if the correlation property exists
      return unless aggregateId = message.meta? and message.meta[this.eventCorrelationProperty]
    @log.debug(@_logMsg("Handling message #{message.typeName()} for
                       #{@eventSourceable}<#{aggregateId}>\n"), message)
    eventSourceable = @repository.find @eventSourceable, aggregateId
    @injector.injectInto(eventSourceable)
    throw Router.ERRORS.cannotHandleMessage(message) if !eventSourceable?
    eventSourceable = @_handleDomainErrors(-> eventSourceable.handle message)
    @repository.save(eventSourceable) if eventSourceable?

  _logMsg: (message) -> "#{@configuration.appId}: #{this}: #{message}"

  _handleDomainErrors: (fn) ->
    try
      return fn.call(this)
    catch error
      @log.error(@_logMsg(error.message))
      if error instanceof Space.Error
        this.publish(new Space.domain.Exception({
          thrower: @eventSourceable.toString(),
          error: error
        }))
        return null
      else
        throw error
