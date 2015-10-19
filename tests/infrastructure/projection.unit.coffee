
describe 'Space.eventSourcing.Projection', ->

  class TestEvent extends Space.messaging.Event
  class TestProjection extends Space.eventSourcing.Projection

  beforeEach ->
    @handler = sinon.spy()
    @projection = new TestProjection({
      eventBus: new Space.messaging.EventBus()
      meteor: Meteor
      underscore: _
    })
    @projection.onDependenciesReady()
    @projection.subscribe TestEvent, @handler
    @testEvent = new TestEvent()

  describe 'replay mode', ->

    it 'does not handle normal events', ->
      @projection.enterReplayMode()
      @projection.on @testEvent
      expect(@handler).not.to.have.been.called

    it 'handles replayed events', ->
      @projection.enterReplayMode()
      @projection.on @testEvent, true # replay=true
      expect(@handler).to.have.been.calledWithExactly @testEvent

    it 'handles queued events when exiting replay mode', ->
      @projection.enterReplayMode()
      @projection.on @testEvent
      @projection.exitReplayMode()
      expect(@handler).to.have.been.calledWithExactly @testEvent
