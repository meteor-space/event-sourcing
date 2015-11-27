class Space.eventSourcing.Router extends Space.messaging.Controller

  @type 'Space.eventSourcing.Router'

  dependencies: {
    configuration: 'configuration'
    repository: 'Space.eventSourcing.Repository'
    commitStore: 'Space.eventSourcing.CommitStore'
    log: 'log'
  }

  @ERRORS: {

    managedEventSourcableNotSpecified: 'Please specify a Router::eventSourcable
    class to be managed by the router.'

    missingInitializingMessage: 'Please specify Router::initializingMessage
    (an event or command class) that will be used to create new instanes of
    the managed eventSourcable.'

    missingEventCorrelationProperty: 'Please specify Process::eventCorrelationProperty
    that will be used to route events to the managed eventSourcable.'

    cannotHandleMessage: (message, id) ->
      new Error "No eventSourcable <#{id}> found to handle #{message.typeName()}"
  }

  eventSourcable: null
  initializingMessage: null
  routeEvents: null
  routeCommands: null
  eventCorrelationProperty: null

  constructor: ->
    if not @eventSourcable?
      throw new Error Router.ERRORS.managedEventSourcableNotSpecified
    if not @initializingMessage?
      throw new Error Router.ERRORS.missingInitializingMessage
    @routeEvents ?= []
    @eventCorrelationProperty = @eventSourcable::eventCorrelationProperty
    if @routeEvents.length > 0 and not @eventCorrelationProperty?
      throw new Error Router.ERRORS.missingEventCorrelationProperty
    @routeCommands ?= []
    super

  onDependenciesReady: ->
    super
    @_setupInitializingMessage()
    @_routeEventToEventSourcable(eventType) for eventType in @routeEvents
    @_routeCommandToEventSourcable(commandType) for commandType in @routeCommands

  _setupInitializingMessage: ->
    if @initializingMessage.isSubclassOf(Space.messaging.Event)
      @eventBus.subscribeTo @initializingMessage, (event) =>
        @log.info("#{this}: Creating new #{@eventSourcable} with event
                  #{event.typeName()}\n", event)
        @_handleDomainErrors -> @repository.save new @eventSourcable(event)
    else if @initializingMessage.isSubclassOf(Space.messaging.Command)
      @commandBus.registerHandler @initializingMessage, (cmd) =>
        @log.info("#{this}: Creating new #{@eventSourcable} with command
                  #{cmd.typeName()}\n", cmd)
        @_handleDomainErrors -> @repository.save new @eventSourcable(cmd)

  _routeEventToEventSourcable: (eventType) ->
    @eventBus.subscribeTo eventType, @_genericEventHandler

  _routeCommandToEventSourcable: (commandType) ->
    @commandBus.registerHandler commandType, @_genericCommandHandler

  _genericEventHandler: (event) =>
    # Only route this event if the correlation property exists
    return unless event.meta? and event.meta[this.eventCorrelationProperty]?
    correlationId = event.meta[this.eventCorrelationProperty]
    @log.info(@_logMsg("Handling event #{event.typeName()} for
                       #{@eventSourcable}<#{correlationId}>\n"), event)
    eventSourcable = @repository.find @eventSourcable, correlationId
    throw Router.ERRORS.cannotHandleMessage(event) if !eventSourcable?
    @_handleDomainErrors -> @repository.save eventSourcable.handle(event)

  _genericCommandHandler: (command) =>
    if not command? then return
    @log.info(@_logMsg("Handling command #{command.typeName()} for
                       #{@eventSourcable}<#{command.targetId}>"), command)
    eventSourcable = @repository.find @eventSourcable, command.targetId
    throw Router.ERRORS.cannotHandleMessage(command) if !eventSourcable?
    @_handleDomainErrors -> @repository.save eventSourcable.handle(command)

  _logMsg: (message) -> "#{@configuration.appId}: #{this}: #{message}"

  _handleDomainErrors: (fn) ->
    try
      fn.call(this)
    catch error
      this.publish(new Space.domain.Exception({
        thrower: @eventSourcable.toString(),
        error: error
      }))
