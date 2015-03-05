
CommitPublisher = Space.cqrs.CommitPublisher
Event = Space.cqrs.Event
Command = Space.cqrs.Command

describe "Space.cqrs.CommitPublisher", ->

  beforeEach ->

    @publisher = new CommitPublisher()

    # STUBS
    @publisher.commits = update: sinon.stub()
    @publisher.eventBus = publish: sinon.stub()
    @publisher.commandBus = send: sinon.stub()

  it 'declares its dependencies correctly', ->

    expect(CommitPublisher).to.dependOn {
      commits: 'Space.cqrs.CommitCollection'
      eventBus: 'Space.messaging.EventBus'
      commandBus: 'Space.messaging.CommandBus'
    }

  describe '#publishCommit', ->

    it 'publishes the events and commands of the commit', ->

      testEvent = sourceId: '123'
      testCommand = sourceId: '123'

      commit =
        sourceId: "123"
        version: 1
        changes:
          events: [testEvent]
          commands: [testCommand]
        isPublished: false

      @publisher.publishCommit commit

      expect(@publisher.eventBus.publish).to.have.been.calledWith testEvent
      expect(@publisher.commandBus.send).to.have.been.calledWith testCommand
