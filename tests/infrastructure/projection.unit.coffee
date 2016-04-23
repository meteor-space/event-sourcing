
describe 'Space.eventSourcing.Projection', ->

  class TestEvent extends Space.domain.Event
    @type 'Space.messaging.TestEvent'
  class TestProjection extends Space.eventSourcing.Projection
    @type 'Space.eventSourcing.TestProjection'

  beforeEach ->
    @handler = sinon.spy()
    @projection = new TestProjection({
      eventBus: new Space.messaging.EventBus()
      meteor: Meteor
      underscore: _
      log: {
        debug: ->
        warning: ->
        info: ->
        error: ->
      }
    })
    @projection.onDependenciesReady()
    @projection.subscribe TestEvent, @handler
    @testEvent = new TestEvent()

  describe 'projection state', ->

    it 'handles events by default', ->
      @projection.on @testEvent
      expect(@handler).to.have.been.called

  describe 'rebuild mode', ->

    it 'does not handle non-rebuild in real-time', ->
      @projection.enterRebuildMode()
      @projection.on @testEvent
      expect(@handler).not.to.have.been.called

    it 'handles rebuild events', ->
      @projection.enterRebuildMode()
      @projection.on @testEvent, true # isRebuildEvent=true
      expect(@handler).to.have.been.calledWithExactly @testEvent

    it 'handles queued events when exiting rebuild mode', ->
      @projection.enterRebuildMode()
      @projection.on @testEvent
      @projection.exitRebuildMode()
      expect(@handler).to.have.been.calledWithExactly @testEvent
