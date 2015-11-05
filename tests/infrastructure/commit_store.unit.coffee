
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

      sourceId = '123'
      firstEvent = new CreatedEvent sourceId: sourceId
      secondEvent = new QuantityChangedEvent sourceId: sourceId, quantity: 1
      thirdEvent = new TotalChangedEvent sourceId: sourceId, total: 10

      @commitStore.add { events: [firstEvent] }, sourceId, 0
      @commitStore.add { events: [secondEvent, thirdEvent] }, sourceId, 1

      events = @commitStore.getEvents sourceId

      expect(event).to.be.instanceof(Event) for event in events

      # Set expected versions of the events
      firstEvent.version = 1
      secondEvent.version = thirdEvent.version = 2
      expect(events).toMatch [firstEvent, secondEvent, thirdEvent]

    it 'skips events if a version offset is given', ->

      sourceId = '123'
      versionOffset = 2
      firstEvent = new CreatedEvent sourceId: sourceId
      secondEvent = new QuantityChangedEvent sourceId: sourceId, quantity: 1
      thirdEvent = new TotalChangedEvent sourceId: sourceId, total: 10
      @commitStore.add {events: [firstEvent]}, sourceId, 0
      @commitStore.add {events: [secondEvent]}, sourceId, 1
      @commitStore.add {events: [thirdEvent]}, sourceId, 2

      events = @commitStore.getEvents sourceId, versionOffset
      secondEvent.version = 2
      thirdEvent.version = 3
      expect(events).toMatch [secondEvent, thirdEvent]
