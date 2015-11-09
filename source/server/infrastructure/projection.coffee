class Space.eventSourcing.Projection extends Space.Object

  @mixin Space.messaging.EventSubscribing

  Collections: {}
  _isInReplayMode: false
  _queuedEvents: null

  constructor: ->
    super
    @_queuedEvents = []
    @Dependencies = {}
    _.extend @Dependencies, @constructor::Dependencies, @Collections

  on: (event, isReplay=false) ->
    return unless @canHandleEvent(event)
    if !@_isInReplayMode or (@_isInReplayMode and isReplay)
      Space.messaging.EventSubscribing.on.call this, event
    else
      @_queuedEvents.push event

  enterReplayMode: -> @_isInReplayMode = true

  exitReplayMode: ->
    @_isInReplayMode = false
    @on(event) for event in @_queuedEvents
