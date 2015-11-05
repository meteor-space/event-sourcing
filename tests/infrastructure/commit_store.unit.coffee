
CommitStore = Space.eventSourcing.CommitStore
Event = Space.messaging.Event
Command = Space.messaging.Command

# =========== TEST DATA ========== #

class TestEvent extends Event
  @type 'Space.eventSourcing.CommitStore.TestEvent'

class TestCommand extends Command
  @type 'Space.eventSourcing.CommitStore.TestCommand'

class CreatedEvent extends Event
  @type 'tests.CommitStore.CreatedEvent', ->

class QuantityChangedEvent extends Event
  @type 'tests.CommitStore.QuantityChangedEvent'
  @fields: quantity: Match.Integer

class TotalChangedEvent extends Event
  @type 'tests.CommitStore.TotalChangedEvent'
  @fields: total: Number

# =========== SPECS ============= #

describe "Space.eventSourcing.CommitStore", ->

  beforeEach ->
    @appId = 'TestApp'
    @commitStore = new CommitStore {
      commits: new Mongo.Collection(null)
      commitPublisher: publishCommit: sinon.spy()
      configuration: { appId: @appId }
      log: ->
    }

  describe '#add', ->

    it 'inserts changes as serialized and versioned commit', ->

      sourceId = '123'
      testEvent = new TestEvent sourceId: sourceId
      testCommand = new TestCommand targetId: sourceId

      changes = events: [testEvent], commands: [testCommand]
      expectedVersion = 0
      newVersion = expectedVersion + 1
      lastCommit = version: expectedVersion

      @commitStore.add changes, sourceId, expectedVersion
      insertedCommits = @commitStore.commits.find().fetch()

      serializedCommit = {
        _id: insertedCommits[0]._id
        sourceId: sourceId
        version: newVersion
        changes:
          events: [EJSON.stringify(testEvent)]
          commands: [EJSON.stringify(testCommand)]
        insertedAt: sinon.match.date
        sentBy: @appId
        receivedBy: [@appId]
        eventTypes: [TestEvent.toString()]
      }

      expect(insertedCommits).toMatch [serializedCommit]
      expect(@commitStore.commitPublisher.publishCommit)
      .to.have.been.calledWithMatch changes: {
        events: [testEvent]
        commands: [testCommand]
      }

  describe '#getEvents', ->

    it 'returns all events versioned by batch for given aggregate', ->

      fakeTimers = sinon.useFakeTimers('Date')
      sourceId = '123'
      firstChanges = events: [new CreatedEvent sourceId: sourceId]

      secondChanges = events: [
        new QuantityChangedEvent sourceId: sourceId, quantity: 1
        new TotalChangedEvent sourceId: sourceId, total: 10
      ]

      @commitStore.add firstChanges, sourceId, 0
      @commitStore.add secondChanges, sourceId, 1

      events = @commitStore.getEvents sourceId

      for event in events
        expect(event).to.be.instanceof Event

      expect(events).to.deep.equal [
        new CreatedEvent sourceId: sourceId, version: 1
        new QuantityChangedEvent sourceId: sourceId, quantity: 1, version: 2
        new TotalChangedEvent sourceId: sourceId, total: 10, version: 2
      ]
      fakeTimers.restore()

    it 'skips events if a version offset is given', ->

      sourceId = '123'
      versionOffset = 2
      @commitStore.add {events: [new CreatedEvent sourceId: sourceId]}, sourceId, 0
      @commitStore.add {events: [new QuantityChangedEvent sourceId: sourceId, quantity: 1]}, sourceId, 1
      @commitStore.add {events: [new TotalChangedEvent sourceId: sourceId, total: 10]}, sourceId, 2

      events = @commitStore.getEvents sourceId, versionOffset
      expect(events).toMatch [
        new QuantityChangedEvent sourceId: sourceId, quantity: 1, version: 2
        new TotalChangedEvent sourceId: sourceId, total: 10, version: 3
      ]
