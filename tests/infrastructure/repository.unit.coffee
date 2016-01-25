Repository = Space.eventSourcing.Repository
CommitStore = Space.eventSourcing.CommitStore
Aggregate = Space.eventSourcing.Aggregate
Event = Space.domain.Event
Command = Space.domain.Command

# =========== TEST DATA ========== #

class MyAggregate extends Aggregate
  @type 'Space.eventSourcing.CommitStore.TestEvent'

class InitiatingCommand extends Command
  @type 'Space.eventSourcing.Repository.InitiatingCommand'

class CreatedEvent extends Event
  @type 'Space.eventSourcing.Repository.CreatedEvent', ->

# =========== SPECS ============= #

describe "Space.eventSourcing.Repository", ->

  beforeEach ->
    @clock = sinon.useFakeTimers(Date.now(), 'Date')
    @appId = 'TestApp'
    @aggregateId = new Guid()
    @initiatingCommand = new InitiatingCommand({
      targetId: @aggregateId
      timestamp: new Date()
    })
    @createdEvent = new CreatedEvent({
      sourceId: @aggregateId
      version: 0
      timestamp: new Date()
    })
    @myAggregate = new Aggregate(@aggregateId, @initiatingCommand)
    @myAggregate.record(@createdEvent)
    @commitStore = new CommitStore {
      commits: new Mongo.Collection(null)
      commitPublisher: { publishCommit: -> }
      configuration: { appId: @appId }
      log: Space.log
    }
    @repository = new Repository {
      commitStore: @commitStore
    }


  afterEach ->
    @clock.restore()

  describe '#save', ->

    it 'saves changes from the provided aggregate instance as a serialized and versioned commit', ->

      expectedVersion = 1
      @repository.save @myAggregate
      insertedCommits = @commitStore.commits.find().fetch()

      expectedCommit = {
        _id: insertedCommits[0]._id
        sourceId: @aggregateId.toString()
        version: expectedVersion
        changes:
          events: [type: @createdEvent.typeName(), data: @createdEvent.toData()]
          commands: []
        insertedAt: sinon.match.date
        sentBy: @appId
        receivers: [{ appId: @appId, receivedAt: new Date() }]
        eventTypes: [@createdEvent.toString()]
      }

      expect(insertedCommits).toMatch [expectedCommit]
