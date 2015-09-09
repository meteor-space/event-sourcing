
{Projection} = Space.eventSourcing

describe 'Space.eventSourcing.Projection', ->

  class TestEvent extends Space.messaging.Event
  class TestProjection extends Projection

  beforeEach ->
    @handler = sinon.spy()
    TestProjection.on TestEvent, @handler
    @projection = new TestProjection()
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
