
AggregateRoot = Space.cqrs.AggregateRoot
Event = Space.cqrs.Event

# ========================= CONSTRUCTION ============================== #

describe "#{AggregateRoot}", ->

  class TestEvent extends Event
    @type 'TestEvent'

  beforeEach ->

    @aggregateId = '123'

    @event = event = new TestEvent {
      sourceId: @aggregateId
      data: {}
      version: 2
    }

    @handler = handler = sinon.spy()

    class TestAggregate extends AggregateRoot

      @handle event.typeName(), handler

    @aggregate = new TestAggregate @aggregateId


  describe 'construction', ->

    it 'requires an id on creation', ->
      expect(-> new AggregateRoot()).to.throw AggregateRoot.UID_REQUIRED_ERROR

    it 'makes the id publicly available', ->
      id = '123'
      aggregate = new AggregateRoot id

      expect(aggregate.getId()).to.equal id

    it 'initializes uncommitted changes to empty array', ->
      aggregate = new AggregateRoot '123'

      expect(aggregate.getEvents()).to.eql []

    it 'sets the initial version to 0', ->
      aggregate = new AggregateRoot '123'

      expect(aggregate.getVersion()).to.eql 0


  describe "#record", ->

    it 'handles the given event', ->

      @aggregate.record @event
      expect(@handler).to.have.been.calledWithExactly @event

    it 'appends the event to the queue', ->

      @aggregate.record @event
      expect(@aggregate.getEvents()).to.eql [@event]

    it 'only takes domain events', ->

      event = type: 'Test', aggregateId: 'bla'
      expect(=> @aggregate.record(event)).to.throw AggregateRoot.ERRORS.domainEventRequired

    it 'throws if no handler is defined for the event', ->

      event = new TestEvent sourceId: '123'
      aggregate = new AggregateRoot '123'

      expectedError = AggregateRoot.ERRORS.cannotHandleEvent + event.typeName()

      expect(-> aggregate.record event).to.throw expectedError

    it 'does not append the event to the queue if something fails', ->

      expect(=> @aggregate.record()).to.throw Error
      expect(=> @aggregate.record 'unknownEvent', {}).to.throw Error
      expect(@aggregate.getEvents()).to.eql []


  describe "#replay", ->

    it 'invokes the mapped event handler', ->

      @aggregate.replay @event
      expect(@handler).to.have.been.calledWithExactly @event

    it 'does not add the event as uncommitted change', ->

      @aggregate.replay @event
      expect(@aggregate.getEvents()).to.eql []

    it 'throws error when the event is not a domain event', ->

      aggregate = @aggregate

      expect(-> aggregate.replay()).to.throw AggregateRoot.DOMAIN_EVENT_REQUIRED_ERROR
      expect(-> aggregate.replay({})).to.throw AggregateRoot.DOMAIN_EVENT_REQUIRED_ERROR

    it 'it assigns the event version to the aggregate', ->

      @aggregate.replay @event
      expect(@aggregate.getVersion()).to.equal @event.version

    it 'also accepts events that have no version', ->

      @aggregate.replay new TestEvent sourceId: @aggregateId
      expect(@aggregate.getVersion()).to.equal 0

    it 'only replays events that have the right source id', ->

      event = new TestEvent sourceId: 'otherId'
      expect(=> @aggregate.replay event).to.throw AggregateRoot.INVALID_EVENT_SOURCE_ID_ERROR

  describe '#isHistory', ->

    it 'checks if the given param is of type array', ->
      aggregate = new AggregateRoot '123'
      expect(aggregate.isHistory []).to.be.true

  describe '#replayHistory', ->

    class Created extends Event
      @type 'Created'

    class SomethingChanged extends Event
      @type 'SomethingChanged'

    class ChangedAgain extends Event
      @type 'ChangedAgain'

    it 'replays given historic events on the aggregate', ->

      id = '123'
      aggregate = new AggregateRoot id

      replaySpy = sinon.stub aggregate, 'replay'

      history = [
        new Created sourceId: id, data: {}, version: 1
        new SomethingChanged sourceId: id, data: {}, version: 2
        new ChangedAgain sourceId: id, data: {}, version: 3
      ]

      aggregate.replayHistory history

      expect(replaySpy).to.have.been.calledThrice
      expect(replaySpy).to.have.been.calledWithExactly history[0]
      expect(replaySpy).to.have.been.calledWithExactly history[1]
      expect(replaySpy).to.have.been.calledWithExactly history[2]
