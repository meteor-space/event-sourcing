class Space.eventSourcing.Projection extends Space.Object

  @mixin Space.messaging.EventSubscribing

  collections: {}
  _state: null
  _queuedEvents: null

  constructor: ->
    super
    @_state = 'projecting'
    @_queuedEvents = []
    @dependencies = {
      configuration: 'configuration'
      log: 'log'
    }
    _.extend @dependencies, @constructor::dependencies, @collections

  on: (event, isRebuildEvent=false) ->
    return unless @canHandleEvent(event)
    if @_is('projecting') or (@_is('rebuilding') and isRebuildEvent)
      Space.messaging.EventSubscribing.on.call this, event
    else
      @_queuedEvents.push event

  enterRebuildMode: ->
    if @_is('rebuilding')
      throw new Space.eventSourcing.ProjectionAlreadyRebuilding(@constructor.toString())
    @_state = 'rebuilding'
    @log.debug(@_logMsg("State: #{@_state}"))


  exitRebuildMode: ->
    if !@_is('rebuilding')
      throw new Space.eventSourcing.ProjectionNotRebuilding(@constructor.toString())
    @_state = 'projecting'
    @on(event) for event in @_queuedEvents
    @log.debug(@_logMsg("State: #{@_state}"))

  _is: (expectedState) ->
    true if expectedState is @_state

  _logMsg: (message) ->
    prefix = "#{@configuration.appId}: " if @configuration?.appId
    "#{prefix}#{this}: #{message}"
