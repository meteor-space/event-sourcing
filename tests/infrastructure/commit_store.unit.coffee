
CommitStore = Space.cqrs.CommitStore
Event = Space.cqrs.Event
Command = Space.cqrs.Command

describe "#{CommitStore}", ->

  beforeEach ->
    @commitStore = new CommitStore()
    @commitStore.commits = new Mongo.Collection(null)
    @commitStore.publisher = publishCommit: sinon.spy()

  it 'defines its dependencies correctly', ->

    expect(CommitStore).to.dependOn {
      commits: 'Space.cqrs.CommitCollection'
      publisher: 'Space.cqrs.CommitPublisher'
    }

  describe '#add', ->

    class TestEvent extends Event
      @type 'Space.cqrs.CommitStore.TestEvent'

    class TestCommand extends Command
      @type 'Space.cqrs.CommitStore.TestCommand'

    it 'inserts given changes as versioned commit', ->

      sourceId = '123'
      testEvent = new TestEvent sourceId: sourceId
      testCommand = new TestCommand sourceId: sourceId

      changes = events: [testEvent], commands: [testCommand]
      expectedVersion = 0
      newVersion = expectedVersion + 1
      lastCommit = version: expectedVersion

      @commitStore.add changes, sourceId, expectedVersion
      addedCommits = @commitStore.commits.find().fetch()

      expectedCommit =
        sourceId: sourceId
        version: newVersion
        changes: changes
        isPublished: false
        _id: addedCommits[0]._id

      expect(addedCommits).to.deep.equal [expectedCommit]
      expect(@commitStore.publisher.publishCommit).to.have.been.calledWithMatch expectedCommit

  describe '#getEvents', ->

    it 'returns all events versioned by batch for given aggregate', ->

      sourceId = '123'

      class CreatedEvent extends Event
        @type 'tests.CommitStore.CreatedEvent'

      class QuantityChangedEvent extends Event

        @type 'tests.CommitStore.QuantityChangedEvent'

        toJSONValue: -> {
          sourceId: @sourceId
          version: @version
          data:
            quantity: @data.quantity
        }

      class TotalChangedEvent extends Event
        @type 'tests.CommitStore.TotalChangedEvent'

      firstChanges = events: [new CreatedEvent sourceId: sourceId]

      secondChanges = events: [
        new QuantityChangedEvent sourceId: sourceId, data: { quantity: 1 }
        new TotalChangedEvent sourceId: sourceId, data: { total: 10 }
      ]

      @commitStore.add firstChanges, sourceId, 0
      @commitStore.add secondChanges, sourceId, 1

      events = @commitStore.getEvents sourceId

      for event in events
        expect(event).to.be.instanceof Event

      expect(events).to.eql [
        new CreatedEvent sourceId: sourceId, version: 1
        new QuantityChangedEvent sourceId: sourceId, data: { quantity: 1 }, version: 2
        new TotalChangedEvent sourceId: sourceId, data: { total: 10 }, version: 2
      ]
