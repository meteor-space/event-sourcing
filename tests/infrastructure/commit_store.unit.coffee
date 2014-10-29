
CommitStore = Space.cqrs.CommitStore
Event = Space.cqrs.Event
globalNamespace = this

describe "#{CommitStore}", ->

  beforeEach ->

    @testNamespace = {}

    @commits =
      insert: sinon.spy()
      find: sinon.stub()
      findOne: sinon.stub()
      update: sinon.spy()

    @commitPublisher = publishCommit: sinon.spy()

    @commitStore = new CommitStore()
    @commitStore.commits = @commits
    @commitStore.publisher = @commitPublisher
    @commitStore.globalNamespace = @testNamespace

  it 'defines its dependencies correctly', ->

    expect(CommitStore::Dependencies).to.eql {
      commits: 'Space.cqrs.CommitCollection'
      publisher: 'Space.cqrs.CommitPublisher'
    }

  it 'uses the global namespace by default', ->
    store = new CommitStore()
    expect(store.globalNamespace).to.equal globalNamespace

  describe '#add', ->

    it 'inserts given events as versioned commit into the collection', ->

      sourceId = '123'
      testEvent = new Event type: 'testEvent', sourceId: sourceId
      changes = events: [testEvent]
      expectedVersion = 1
      newVersion = expectedVersion + 1
      lastCommit = version: expectedVersion

      # simulate successful fetch of last batch
      @commitStore.commits.findOne
        .withArgs(
          { sourceId: sourceId }, # selector
          { sort: [['version', 'desc']], fields: { version: 1 } } # options
        )
        .returns lastCommit

      @commitStore.add changes, sourceId, expectedVersion

      expectedCommit =
        sourceId: sourceId
        version: newVersion
        changes: changes
        isPublished: false

      expect(@commitStore.commits.insert).to.have.been.calledWithMatch expectedCommit

      expect(@commitPublisher.publishCommit).to.have.been.calledWithMatch expectedCommit

  describe '#getEvents', ->

    it 'returns all events versioned by batch for given aggregate', ->

      sourceId = '123'

      class @testNamespace.CreatedEvent extends Event
      class @testNamespace.QuantityChangedEvent extends Event
      class @testNamespace.TotalChangedEvent extends Event

      savedCommits = [
        {
          sourceId: sourceId
          version: 1,
          changes:
            events: [
              { type: 'CreatedEvent', sourceId: sourceId, data: {}, version: 1 }
            ]
        },
        {
          sourceId: sourceId
          version: 2,
          changes:
            events: [
              { type: 'QuantityChangedEvent', sourceId: sourceId, data: {}, version: 2 }
              { type: 'TotalChangedEvent', sourceId: sourceId, data: {}, version: 2 }
            ]
        }
      ]

      # simulate successful fetch all batches
      @commitStore.commits.find
        .withArgs(
          { sourceId: sourceId }, # selector
          { sort: [['version', 'asc']] } # options
        )
        .returns savedCommits

      events = @commitStore.getEvents sourceId

      for event in events
        expect(event).to.be.instanceof Event

      expect(events).to.eql [
        new @testNamespace.CreatedEvent type: 'CreatedEvent', sourceId: sourceId, version: 1
        new @testNamespace.QuantityChangedEvent type: 'QuantityChangedEvent', sourceId: sourceId, version: 2
        new @testNamespace.TotalChangedEvent type: 'TotalChangedEvent', sourceId: sourceId, version: 2
      ]

    it 'throws an error if a given event class could not be found on the namespace', ->

      sourceId = '123'

      savedCommits = [
        {
          sourceId: sourceId
          version: 1,
          changes:
            events: [
              { type: 'UnknownEvent', sourceId: sourceId, data: {}, version: 1 }
            ]
        }
      ]

      # simulate successful fetch all batches
      @commitStore.commits.find.returns savedCommits

      callWithWrongSavedEvents = => @commitStore.getEvents sourceId

      expect(callWithWrongSavedEvents).to.throw CommitStore.EVENT_CLASS_LOOKUP_ERROR + '<UnknownEvent>'