
CommitPublisher = Space.cqrs.CommitPublisher
Event = Space.cqrs.Event
Command = Space.cqrs.Command

describe "#{CommitPublisher}", ->

  beforeEach ->

    @testNamespace = {}

    @publisher = new CommitPublisher()
    @publisher.globalNamespace = @testNamespace

    # STUBS
    @commitsStub = update: sinon.stub()
    @eventBusStub = publish: sinon.stub()
    @commandBusStub = send: sinon.stub()

    @publisher.commits = @commitsStub
    @publisher.eventBus = @eventBusStub
    @publisher.commandBus = @commandBusStub

  it 'declares its dependencies correctly', ->

    expect(CommitPublisher::Dependencies).to.eql {
      commits: 'Space.cqrs.CommitCollection'
      eventBus: 'Space.cqrs.EventBus'
      commandBus: 'Space.cqrs.CommandBus'
    }

  describe '#publishCommit', ->

  it 'publishes the events and commands of the commit', ->

    testEvent = type: 'TestEvent', sourceId: '123'
    testCommand = type: 'TestCommand', sourceId: '123'

    @testNamespace.TestEvent = sinon.stub().returns testEvent
    @testNamespace.TestCommand = sinon.stub().returns testCommand

    commit =
      sourceId: "123"
      version: 1
      changes:
        events: [type: 'TestEvent', sourceId: '123']
        commands: [type: 'TestCommand', sourceId: '123']
      isPublished: false

    @publisher.publishCommit commit

    expect(@testNamespace.TestEvent).to.have.been.calledWithNew
    expect(@eventBusStub.publish).to.have.been.calledWithMatch testEvent
    expect(@commandBusStub.send).to.have.been.calledWithMatch @testNamespace.TestCommand, testCommand

