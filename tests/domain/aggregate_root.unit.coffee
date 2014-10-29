
AggregateRoot = Space.cqrs.AggregateRoot
Event = Space.cqrs.Event

# ========================= CONSTRUCTION ============================== #

describe "#{AggregateRoot}", ->

  beforeEach ->
    @aggregateId = '123'
    @aggregate = new AggregateRoot @aggregateId

    @event = new Event {
      type: 'test'
      sourceId: @aggregateId
      data: {}
      version: 2
    }

    @handler = sinon.spy()
    @aggregate.mapEvents @event.type, @handler

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


  describe "#applyEvent", ->

    it 'takes a domain event as required parameter', ->

      expect(=> @aggregate.applyEvent(@event)).not.to.throw Error

    it 'only takes domain events', ->

      event = type: 'Test', aggregateId: 'bla'
      expect(=> @aggregate.applyEvent(event)).to.throw AggregateRoot.DOMAIN_EVENT_REQUIRED_ERROR

    it 'throws if no handler is defined for the event', ->

      event = new Event type: 'Event', sourceId: '123'
      aggregate = new AggregateRoot '123'

      expectedError = AggregateRoot.CANNOT_HANDLE_EVENT_ERROR + 'Event'

      expect(-> aggregate.applyEvent event).to.throw expectedError

    it 'no events get appended when something fails', ->

      expect(=> @aggregate.applyEvent()).to.throw Error
      expect(=> @aggregate.applyEvent 'unknownEvent', {}).to.throw Error
      expect(@aggregate.getEvents()).to.eql []


  describe "#replayEvent", ->

    it 'invokes the mapped event handler', ->

      @aggregate.replayEvent @event
      expect(@handler).to.have.been.calledWithExactly @event

    it 'does not add the event as uncommitted change', ->

      @aggregate.replayEvent @event
      expect(@aggregate.getEvents()).to.eql []

    it 'throws error when the event is not a domain event', ->

      aggregate = @aggregate

      expect(-> aggregate.replayEvent()).to.throw AggregateRoot.DOMAIN_EVENT_REQUIRED_ERROR
      expect(-> aggregate.replayEvent({})).to.throw AggregateRoot.DOMAIN_EVENT_REQUIRED_ERROR

    it 'it assigns the event version to the aggregate', ->

      @aggregate.replayEvent @event
      expect(@aggregate.getVersion()).to.equal @event.version

    it 'also accepts events that have no version', ->

      @aggregate.replayEvent new Event type: @event.type, sourceId: @aggregateId
      expect(@aggregate.getVersion()).to.equal 0

    it 'only replays events that have the right source id', ->

      event = new Event type: @event.type, sourceId: 'otherId'
      expect(=> @aggregate.replayEvent event).to.throw AggregateRoot.INVALID_EVENT_SOURCE_ID_ERROR


  describe "#mapEvents", ->

    # SHARED SETUP
    aggregateId = '123'
    firstEvent = new Event type: 'first-event', sourceId: aggregateId
    secondEvent = new Event type: 'second-event', sourceId: aggregateId
    eventData = {}

    it 'maps event types to handler functions', ->

      aggregate = new AggregateRoot aggregateId

      firstHandler = sinon.spy()
      secondHandler = sinon.spy()

      aggregate.mapEvents(
        firstEvent.type, firstHandler,
        secondEvent.type, secondHandler,
      )

      aggregate.applyEvent firstEvent
      aggregate.applyEvent secondEvent

      expect(firstHandler).to.have.been.calledWith firstEvent
      expect(firstHandler).to.have.been.calledOn aggregate

      expect(secondHandler).to.have.been.calledWith secondEvent
      expect(secondHandler).to.have.been.calledOn aggregate

    it 'correctly applied events get appended as uncommitted changes', ->

      aggregate = new AggregateRoot aggregateId

      firstHandler = sinon.spy()
      secondHandler = sinon.spy()

      aggregate.mapEvents(
        firstEvent.type, firstHandler,
        secondEvent.type, secondHandler,
      )

      aggregate.applyEvent firstEvent
      aggregate.applyEvent secondEvent

      changes = aggregate.getEvents()

      expect(changes).to.eql [firstEvent, secondEvent]

  describe '#isHistory', ->

    it 'checks if the given param is of type array', ->
      aggregate = new AggregateRoot '123'
      expect(aggregate.isHistory []).to.be.true

  describe '#loadHistory', ->

    it 'replays given historic events on the aggregate', ->

      id = '123'
      aggregate = new AggregateRoot id

      replaySpy = sinon.stub aggregate, 'replayEvent'

      history = [
        new Event type: 'created', sourceId: id, data: {}, version: 1
        new Event type: 'somethingChanged', sourceId: id, data: {}, version: 2
        new Event type: 'changedAgain', sourceId: id, data: {}, version: 3
      ]

      aggregate.loadHistory history

      expect(replaySpy).to.have.been.calledThrice
      expect(replaySpy).to.have.been.calledWithExactly history[0]
      expect(replaySpy).to.have.been.calledWithExactly history[1]
      expect(replaySpy).to.have.been.calledWithExactly history[2]
