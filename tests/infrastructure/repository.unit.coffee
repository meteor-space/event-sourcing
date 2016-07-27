Repository = Space.eventSourcing.Repository
CommitStore = Space.eventSourcing.CommitStore
Aggregate = Space.eventSourcing.Aggregate
Process = Space.eventSourcing.Process
Event = Space.domain.Event
Command = Space.domain.Command

# =========== TEST DATA ========== #

class MyAggregate extends Aggregate
  @type 'Space.eventSourcing.Repository.MyAggregate'

class MyProcess extends Process
  @type 'Space.eventSourcing.Repository.MyProcess'

class MyInitiatingCommand extends Command
  @type 'Space.eventSourcing.Repository.MyInitiatingCommand'

class MyTriggeredCommand extends Command
  @type 'Space.eventSourcing.Repository.MyTriggeredCommand'

class MyCreatedEvent extends Event
  @type 'Space.eventSourcing.Repository.MyCreatedEvent', ->

# =========== SPECS ============= #

describe "Space.eventSourcing.Repository", ->

  beforeEach ->
    @clock = sinon.useFakeTimers(Date.now(), 'Date')
    @appId = 'TestApp'
    @aggregateId = new Guid()
    @targetId = new Guid()
    @myInitiatingCommand = new MyInitiatingCommand({
      targetId: @aggregateId
      timestamp: new Date()
    })
    @myTriggeredCommand = new MyTriggeredCommand({
      targetId: @targetId
      timestamp: new Date()
    })
    @myCreatedEvent = new MyCreatedEvent({
      sourceId: @aggregateId
      version: 0
      timestamp: new Date()
    })
    @commitStore = new CommitStore {
      commits: new Mongo.Collection(null)
      commitPublisher: { publishChanges: -> }
      configuration: { appId: @appId }
      log: Space.log
    }
    @repository = new Repository {
      commitStore: @commitStore
    }


  afterEach ->
    @clock.restore()

  describe '#save', ->

    it 'persists events from the provided aggregate instance as a serialized and versioned commit', ->

      myAggregate = new MyAggregate(@aggregateId, @initiatingCommand)
      myAggregate.record(@myCreatedEvent)

      expectedVersion = 1
      @repository.save myAggregate
      insertedCommits = @commitStore.commits.find().fetch()

      expectedCommit = {
        _id: insertedCommits[0]._id
        sourceId: @aggregateId.toString()
        version: expectedVersion
        changes:
          events: [type: @myCreatedEvent.typeName(), data: @myCreatedEvent.toData()]
          commands: []
        insertedAt: sinon.match.date
        sentBy: @appId
        receivers: [{ appId: @appId, receivedAt: new Date() }]
        eventTypes: [@myCreatedEvent.toString()]
        commandTypes: []
      }

      expect(insertedCommits).toMatch [expectedCommit]

    it 'persistst events and commands from the provided Process instance as a serialized and versioned commit', ->

      myProcess = new MyProcess(@aggregateId, @myInitiatingCommand)
      myProcess.trigger(@myTriggeredCommand)
      myProcess.record(@myCreatedEvent)

      expectedVersion = 1
      @repository.save myProcess
      insertedCommits = @commitStore.commits.find().fetch()

      expectedCommit = {
        _id: insertedCommits[0]._id
        sourceId: @aggregateId.toString()
        version: expectedVersion
        changes:
          events: [type: @myCreatedEvent.typeName(), data: @myCreatedEvent.toData()]
          commands: [type: @myTriggeredCommand.typeName(), data: @myTriggeredCommand.toData()]
        insertedAt: sinon.match.date
        sentBy: @appId
        receivers: [{ appId: @appId, receivedAt: new Date() }]
        eventTypes: [@myCreatedEvent.toString()]
        commandTypes: [@myTriggeredCommand.toString()]
      }

      expect(insertedCommits).toMatch [expectedCommit]

  describe '#find', ->

    it 'returns a re-hydrated instance of the expected version by type and id', ->
      # Version 1
      myAggregate = new MyAggregate(@aggregateId, @initiatingCommand)
      myAggregate.record(@myCreatedEvent)
      @repository.save(myAggregate)
      myAggregate._events = []
      # Version 2
      myAggregate.record(@myCreatedEvent)
      @repository.save(myAggregate)
      myAggregate._events = []
      rehydratedInstance = @repository.find(MyAggregate, @aggregateId)
      expect(rehydratedInstance).toMatch(myAggregate)
      expect(rehydratedInstance._version).to.equal(2)


