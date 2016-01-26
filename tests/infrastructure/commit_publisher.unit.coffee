
{ CommitStore, CommitPublisher } = Space.eventSourcing

Event = Space.domain.Event
EventBus = Space.messaging.EventBus
Command = Space.domain.Command
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
      meteor: Meteor
      ejson: EJSON
      log: Space.log
    }
#    Un-comment this to log test cases
#    @commitPublisher.log.start()
    @commitStore = new CommitStore {
      commits: Commits
      commitPublisher: @commitPublisher
      configuration: @configuration
      log: Space.log
    }
    @commandHandler = sinon.spy()
    @commitPublisher.commandBus.registerHandler(
      'Space.eventSourcing.CommitPublisher.TestCommand',
      @commandHandler
    )

    @externalReceiveEntry = { appId: 'someOtherApp', receivedAt: new Date() }
    sourceId = '123'
    testEvent = new CPTestEvent sourceId: sourceId
    testCommand = new CPTestCommand targetId: sourceId
    expectedVersion = 0
    newVersion = expectedVersion + 1
    @commitProps = {
      sourceId: sourceId
      version: newVersion
      changes:
        events: [EJSON.stringify(testEvent)]
        commands: [EJSON.stringify(testCommand)]
      insertedAt: new Date()
      sentBy: 'someOtherApp'
      receivers: [@externalReceiveEntry]
      eventTypes: [CPTestEvent.toString()]
    }

    @commitId = Commits.insert @commitProps

  afterEach ->
    @clock.restore()
    Commits.remove {}
    @commitPublisher.stopPublishing()

  it 'publishes externally added commits once in the current app, even with multiple app instances running', ->
    @commitPublisher.publishCommit = sinon.spy()
    @commitPublisher.startPublishing()
    insertedCommit = Commits.findOne(@commitId)
    expect(@commitPublisher.publishCommit).to.have.been.called
    expect(insertedCommit.receivers).to.deep.equal([@externalReceiveEntry, {
      appId: @appId
      receivedAt: new Date()
    }])

  it 'fails the processing attempt if configurable timeout duration is reached', (test, waitFor) ->
    fail = @commitPublisher._failCommitProcessingAttempt = sinon.spy()
    @configuration.eventSourcing.commitProcessing.timeout = 1
    commit = Commits.findOne(@commitId)
    @commitPublisher._setProcessingTimeout(commit)
    timeout = =>
      try
        commit = Commits.findOne(@commitId)
        expect(fail).to.be.calledWith(commit)
      catch err
        test.exception err
    Meteor.setTimeout(waitFor(timeout), 2);

  it 'updates the commit record with the date the processing failed', (test, waitFor) ->
    @configuration.eventSourcing.commitProcessing.timeout = 1
    @commitPublisher.startPublishing()
    timeout = =>
      try
        commit = Commits.findOne(@commitId)
        processedAt = _.findWhere(commit.receivers, {appId: @appId}).processedAt
        expect(processedAt).to.be.instanceOf(Date)
      catch err
        test.exception err
    Meteor.setTimeout(waitFor(timeout), 1000);
