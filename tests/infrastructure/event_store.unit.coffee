
EventStore = Space.cqrs.EventStore
DomainEvent = Space.cqrs.DomainEvent
globalNamespace = this

describe "#{EventStore}", ->

  beforeEach ->

    @testNamespace = {}

    @eventsCollection =
      insert: sinon.spy()
      find: sinon.stub()
      findOne: sinon.stub()

    @eventBusApi = publish: sinon.spy()

    @eventStore = new EventStore()
    @eventStore.eventsCollection = @eventsCollection
    @eventStore.eventBus = @eventBusApi
    @eventStore.globalNamespace = @testNamespace

  it 'defines its dependencies correctly', ->

    expect(EventStore::Dependencies).to.eql {
      eventsCollection: 'Space.cqrs.EventsCollection'
      eventBus: 'Space.cqrs.EventBus'
    }

  it 'uses the global namespace by default', ->
    store = new EventStore()

    expect(store.globalNamespace).to.equal globalNamespace

  describe '#add', ->

    it 'inserts given events as versioned batch into the collection', ->

      aggregateId = '123'
      events = [new DomainEvent type: 'testEvent', sourceId: aggregateId]
      expectedVersion = 1
      lastBatch = version: expectedVersion

      # simulate successful fetch of last batch
      @eventStore.eventsCollection.findOne
        .withArgs(
          { aggregateId: aggregateId }, # selector
          { sort: ['version', 'desc'], fields: { version: 1 } } # options
        )
        .returns lastBatch

      @eventStore.add events, aggregateId, expectedVersion

      expect(@eventStore.eventsCollection.insert).to.have.been.calledWithMatch {
        aggregateId: aggregateId
        version: expectedVersion + 1
        events: events
      }

  describe '#getEvents', ->

    it 'returns all events versioned by batch for given aggregate', ->

      aggregateId = '123'

      class @testNamespace.CreatedEvent extends DomainEvent
      class @testNamespace.QuantityChangedEvent extends DomainEvent
      class @testNamespace.TotalChangedEvent extends DomainEvent

      savedBatches = [
        {
          aggregateId: aggregateId
          version: 1,
          events: [
            { type: 'CreatedEvent', sourceId: aggregateId, data: {}, version: 1 }
          ]
        },
        {
          aggregateId: aggregateId
          version: 2,
          events: [
            { type: 'QuantityChangedEvent', sourceId: aggregateId, data: {}, version: 2 }
            { type: 'TotalChangedEvent', sourceId: aggregateId, data: {}, version: 2 }
          ]
        }
      ]

      # simulate successful fetch all batches
      @eventStore.eventsCollection.find
        .withArgs(
          { aggregateId: aggregateId }, # selector
          { sort: ['version', 'asc'] } # options
        )
        .returns savedBatches

      events = @eventStore.getEvents aggregateId

      for event in events
        expect(event).to.be.instanceof DomainEvent

      expect(events).to.eql [
        new @testNamespace.CreatedEvent type: 'CreatedEvent', sourceId: aggregateId, version: 1
        new @testNamespace.QuantityChangedEvent type: 'QuantityChangedEvent', sourceId: aggregateId, version: 2
        new @testNamespace.TotalChangedEvent type: 'TotalChangedEvent', sourceId: aggregateId, version: 2
      ]