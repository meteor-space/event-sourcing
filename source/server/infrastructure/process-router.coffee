class Space.eventSourcing.ProcessRouter extends Space.messaging.Controller

  @type 'Space.eventSourcing.ProcessRouter'

  @ERRORS: {

    processNotSpecified: 'Please specify a Router::process class to be
    managed by the router.'

    missingInitializingMessage: 'Please specify Router::initializingMessage
    (an event or command class) that will be used to create new instanes of
    the managed process.'

    missingEventCorrelationProperty: 'Please specify Router::eventCorrelationProperty
    that will be used to route events to the managed process.'

    noProcessFoundToHandleEvent: (event, id) ->
      new Error "No process <#{id}> found to handle #{event.typeName()}"
  }

  dependencies: {
    repository: 'Space.eventSourcing.Repository'
    commitStore: 'Space.eventSourcing.CommitStore'
    log: 'Space.eventSourcing.Log'
  }

  process: null
  initializingMessage: null
  routeEvents: null
  eventCorrelationProperty: null

  constructor: ->
    if not @process?
      throw new Error ProcessRouter.ERRORS.processNotSpecified
    if not @initializingMessage?
      throw new Error ProcessRouter.ERRORS.missingInitializingMessage
    if not @eventCorrelationProperty?
      throw new Error ProcessRouter.ERRORS.missingEventCorrelationProperty
    @routeEvents ?= []
    super

  onDependenciesReady: ->
    super
    @_setupInitializingMessage()
    @_routeEventToProcess(eventType) for eventType in @routeEvents

  _setupInitializingMessage: ->
    if @initializingMessage.isSubclassOf(Space.messaging.Event)
      @eventBus.subscribeTo @initializingMessage, (event) =>
        @log "#{this}: Creating new #{@process} with event #{event.typeName()}\n", event
        @repository.save new @process(event)
    else if @initializingMessage.isSubclassOf(Space.messaging.Command)
      @commandBus.registerHandler @initializingMessage, (cmd) =>
        @log "#{this}: Creating new #{@process} with command #{cmd.typeName()}\n", cmd
        @repository.save new @process(cmd)

  _routeEventToProcess: (eventType) ->
    @eventBus.subscribeTo eventType, @_genericEventHandler

  _genericEventHandler: (event) =>
    # Only route this event if the correlation property exists
    return unless event.meta? and event.meta[this.eventCorrelationProperty]?
    correlationId = event.meta[this.eventCorrelationProperty]
    @log "#{this}: Handling event #{event.typeName()} for
          #{@aggregate}<#{correlationId}>\n", event
    process = @repository.find @process, correlationId
    throw ProcessRouter.ERRORS.noProcessFoundToHandleEvent(event) if !process?
    @repository.save process.handle(event)
