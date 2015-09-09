class Space.eventSourcing.Projection extends Space.messaging.Controller

  Collections: {}
  _isInReplayMode: false
  _queuedEvents: null

  constructor: ->
    super
    @_queuedEvents = []
    @Dependencies = {}
    _.extend @Dependencies, @constructor::Dependencies, @Collections

  on: (event, isReplay=false) ->
    if !@_isInReplayMode or (@_isInReplayMode and isReplay)
      super(event)
    else
      @_queuedEvents.push event

  enterReplayMode: -> @_isInReplayMode = true

  exitReplayMode: ->
    @_isInReplayMode = false
    @on(event) for event in @_queuedEvents
