
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
    Commits.remove {}
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
      changes: {
        events: [{
          type: testEvent.typeName(),
          data: testEvent.toData()
        }],
        commands: [{
          type: testCommand.typeName(),
          data: testCommand.toData()
        }]
      }
      insertedAt: new Date()
      sentBy: 'someOtherApp'
      receivers: [@externalReceiveEntry]
      eventTypes: [testEvent.typeName()]
    }

    @commitId = Commits.insert @commitProps
    @changes = (commit) -> @commitPublisher.parseChanges(commit)

  afterEach ->
    @clock.restore()
    @commitPublisher.stopPublishing()
    Commits.remove {}

  it 'publishes externally added commits once in the current app, even with multiple app instances running', ->
    @commitPublisher.publishChanges = sinon.spy()
    @commitPublisher.startPublishing()
    insertedCommit = Commits.findOne(@commitId)
    expect(@commitPublisher.publishChanges).to.have.been.calledWithExactly(
      @changes(insertedCommit), @commitId
    )
    expect(insertedCommit.receivers).to.deep.equal([@externalReceiveEntry, {
      appId: @appId
      receivedAt: new Date()
    }])

  it 'fails the processing attempt if timeout is reached', (test, waitFor) ->
    lockedCommit = Commits.findAndModify({
      query: $and: [_id: @commitId, { 'receivers.appId': { $nin: [@appId] }}]
      update: $push: { receivers: { appId: @appId, receivedAt: new Date() } }
    })
    @commitPublisher._setTimeout(@changes(lockedCommit), @commitId)
    timeout = =>
      try
        commit = Commits.findOne(@commitId)
        failedAt = _.findWhere(commit.receivers, {appId: @appId}).failedAt
        expect(failedAt).to.be.instanceOf(Date)
      catch err
        test.exception err
    Meteor.setTimeout(waitFor(timeout), 20);

  it 'handles errors by setting a failedAt field in the receivers array, and clearing the timeout', ->
    lockedCommit = Commits.findAndModify({
      query: $and: [_id: @commitId, { 'receivers.appId': { $nin: [@appId] }}]
      update: $push: { receivers: { appId: @appId, receivedAt: new Date() } }
    })
    @commitPublisher.eventBus.publish = (event) -> throw new Error 'TestError'
    @commitPublisher._setTimeout = ->
    @commitPublisher._clearTimeout = ->
    try
      @commitPublisher.publishChanges(@changes(lockedCommit), @commitId)
    catch error
      expect(error).to.deep.equal(new Error 'TestError')
    commit = Commits.findOne(@commitId)
    failedAt = _.findWhere(commit.receivers, {appId: @appId}).failedAt
    expect(failedAt).to.be.instanceOf(Date)

  it 'avoids potential race condition between the timeout and processing being marked as completed', ->
    @configuration.eventSourcing.commitProcessing.timeout = 1
    commit = Commits.findAndModify({
      query: { $and: [
        { _id: @commitId },
        { 'receivers.appId': { $nin: [@appId] }}
      ]}
      update: { $push: { receivers: {
        appId: @appId,
        receivedAt: new Date(),
        processedAt: new Date()
      }}}
    })
    @commitPublisher._onTimeout(@changes(commit), @commitId)
    commit = Commits.findOne(@commitId)
    failedAt = _.findWhere(commit.receivers, {appId: @appId}).failedAt
    expect(failedAt).to.equal.undefined

  it "stores each commit's publishing timeout using the id as a the key", ->
    commit = Commits.findOne(@commitId)
    @commitPublisher._onTimeout = ->
    @commitPublisher._setTimeout(@changes(commit), @commitId)
    expect(@commitPublisher._inProgress).to.have.property(@commitId);
    expect(@commitPublisher._inProgress[@commitId]).to.respondTo('_onTimeout');

  it "tracks each commit's publishing timeout when publishing", ->
    mockPublisher = sinon.mock(@commitPublisher)
    commit = Commits.findOne(@commitId)
    mockPublisher.expects("_setTimeout").once().withExactArgs(@changes(commit), @commitId)
    @commitPublisher.publishChanges(@changes(commit), @commitId)
    mockPublisher.verify()

  it "cleans up after the commit is processed, by deleting the object key", ->
    mockPublisher = sinon.mock(@commitPublisher)
    mockPublisher.expects("_cleanupTimeout").once().withExactArgs(@commitId)
    @commitPublisher.startPublishing()
    expect(@commitPublisher._inProgress[@commitId]).to.equal.undefined
    mockPublisher.verify()

  it "is backwards compatible with publishCommit", ->
    mockPublisher = sinon.mock(@commitPublisher)
    mockPublisher.expects("publishChanges").once().withExactArgs(
      @commitProps.changes, @commitId
    )
    commit = Commits.findOne(@commitId)
    @commitPublisher.publishCommit(commit)
    mockPublisher.verify()
