class Space.eventSourcing.ProcessRouter extends Space.messaging.Controller

  @type 'Space.eventSourcing.ProcessRouter'

  @ERRORS: {

    processNotSpecified: 'Please specify a Router::process class to be
    managed by the router.'

    missingInitializingMessage: 'Please specify Router::initializingMessage
    (an event or command class) that will be used to create new instanes of
    the managed process.'

    missingEventCorrelationProperty: 'Please specify Process::eventCorrelationProperty
    that will be used to route events to the managed process.'

    noProcessFoundToHandleMessage: (message, id) ->
      new Error "No process <#{id}> found to handle #{message.typeName()}"
  }

  dependencies: {
    configuration: 'configuration'
    repository: 'Space.eventSourcing.Repository'
    commitStore: 'Space.eventSourcing.CommitStore'
    log: 'log'
  }

  process: null
  initializingMessage: null
  routeEvents: null
  routeCommands: null
  eventCorrelationProperty: null

  constructor: ->
    if not @process?
      throw new Error ProcessRouter.ERRORS.processNotSpecified
    if not @initializingMessage?
      throw new Error ProcessRouter.ERRORS.missingInitializingMessage
    @eventCorrelationProperty = @process::eventCorrelationProperty
    if not @eventCorrelationProperty?
      throw new Error ProcessRouter.ERRORS.missingEventCorrelationProperty
    @routeEvents ?= []
    @routeCommands ?= []
    super

  onDependenciesReady: ->
    super
    @_setupInitializingMessage()
    @_routeEventToProcess(eventType) for eventType in @routeEvents
    @_routeCommandToProcess(commandType) for commandType in @routeCommands

  _setupInitializingMessage: ->
    if @initializingMessage.isSubclassOf(Space.messaging.Event)
      @eventBus.subscribeTo @initializingMessage, (event) =>
        @log.info "#{this}: Creating new #{@process} with event #{event.typeName()}\n", event
        @repository.save new @process(event)
    else if @initializingMessage.isSubclassOf(Space.messaging.Command)
      @commandBus.registerHandler @initializingMessage, (cmd) =>
        @log.info "#{this}: Creating new #{@process} with command #{cmd.typeName()}\n", cmd
        @repository.save new @process(cmd)

  _routeEventToProcess: (eventType) ->
    @eventBus.subscribeTo eventType, @_genericEventHandler

  _routeCommandToProcess: (commandType) ->
    @commandBus.registerHandler commandType, @_genericCommandHandler

  _genericEventHandler: (event) =>
    # Only route this event if the correlation property exists
    return unless event.meta? and event.meta[this.eventCorrelationProperty]?
    correlationId = event.meta[this.eventCorrelationProperty]
    @log.info(@_logMsg("Handling event #{event.typeName()} for #{@process}<#{correlationId}>\n"), event)
    process = @repository.find @process, correlationId
    throw ProcessRouter.ERRORS.noProcessFoundToHandleMessage(event) if !process?
    @repository.save process.handle(event)

  _genericCommandHandler: (command) =>
    if not command? then return
    @log.info(@_logMsg("Handling command #{command.typeName()} for #{@process}<#{command.targetId}>"), command)
    process = @repository.find @process, command.targetId
    throw ProcessRouter.ERRORS.noProcessFoundToHandleMessage(command) if !process?
    @repository.save process.handle(command)

  _logMsg: (message) -> "#{@configuration.appId}: #{this}: #{message}"
