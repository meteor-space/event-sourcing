
{ CommitStore, CommitPublisher } = Space.eventSourcing

Event = Space.messaging.Event
EventBus = Space.messaging.EventBus
Command = Space.messaging.Command
CommandBus = Space.messaging.CommandBus

# =========== TEST DATA ========== #

class CPTestEvent extends Event
  @type 'Space.eventSourcing.CommitPublisher.TestEvent'

class CPTestCommand extends Command
  @type 'Space.eventSourcing.CommitPublisher.TestCommand'

class CPCreatedEvent extends Event
  @type 'tests.CommitPublisher.CreatedEvent', ->

class CPQuantityChangedEvent extends Event
  @type 'tests.CommitPublisher.QuantityChangedEvent'
  @fields: quantity: Match.Integer

class CPTotalChangedEvent extends Event
  @type 'tests.CommitPublisher.TotalChangedEvent'
  @fields: total: Number

# =========== SPECS ============= #

describe "Space.eventSourcing.CommitPublisher", ->

  Commits = new Mongo.Collection('TestCommits')

  beforeEach ->
    @clock = sinon.useFakeTimers(Date.now(), 'Date')
    @appId = 'MyApp'
    @configuration = {
      appId: @appId,
      eventSourcing: {
        commitProcessing: {
          timeout: 20
        }
      }
    }
    Commits.remove {}
    @commitPublisher = new CommitPublisher {
      commits: Commits
      configuration: @configuration
      eventBus: new EventBus { meteor: Meteor }
      commandBus: new CommandBus { meteor: Meteor }
      ejson: EJSON
      commitPublisher: publishCommit: sinon.spy()
      log: new Space.Logger()
    }
    @commitStore = new CommitStore {
      commits: Commits
      commitPublisher: @commitPublisher
      configuration: @configuration
      log: ->
    }
    @commandHandler = sinon.spy()
    @commitPublisher.commandBus.registerHandler(
      'Space.eventSourcing.CommitPublisher.TestCommand',
      @commandHandler
    )

  afterEach ->
    @clock.restore()
    Commits.remove {}
    @commitPublisher.stopPublishing()

  it 'publishes externally added commits once in the current app', ->
    @commitPublisher.publishCommit = sinon.spy()
    sourceId = '123'
    testEvent = new CPTestEvent sourceId: sourceId
    testCommand = new CPTestCommand targetId: sourceId
    changes = events: [testEvent], commands: [testCommand]
    expectedVersion = 0
    newVersion = expectedVersion + 1

    externalReceiveEntry = { appId: 'someOtherApp', receivedAt: new Date() }

    simulatedExternalCommit = {
      sourceId: sourceId
      version: newVersion
      changes:
        events: [EJSON.stringify(testEvent)]
        commands: [EJSON.stringify(testCommand)]
      insertedAt: new Date()
      sentBy: 'someOtherApp'
      receivers: [externalReceiveEntry]
      eventTypes: [CPTestEvent.toString()]
    }

    commitId = Commits.insert simulatedExternalCommit
    @commitPublisher.startPublishing()
    insertedCommit = Commits.findOne(commitId)
    expect(@commitPublisher.publishCommit).to.have.been.called
    expect(insertedCommit.receivers).to.deep.equal([externalReceiveEntry, {
      appId: @appId
      receivedAt: new Date()
    }])

#    it 'fails the processing attempt if an error in the publishing occurs', ->
#
#    it 'fails the processing attempt if configurable timout duration is reached', ->
#
#    it 'logs when processing was completed', ->
