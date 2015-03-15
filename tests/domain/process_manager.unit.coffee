
ProcessManager = Space.cqrs.ProcessManager
Event = Space.messaging.Event

describe "#{ProcessManager}", ->

  class TestCommand

  beforeEach ->
    @event = event = new Event sourceId: '123', version: 1
    @handler = handler = sinon.spy()

    class TestProcess extends ProcessManager
      @handle event.typeName(), handler

    @processManager = new TestProcess '123'

  it 'extends aggregate root', ->
    expect(ProcessManager).to.extend Space.cqrs.Aggregate

  describe 'working with commands', ->

    it 'a processManager generates no commands by default', ->
      expect(@processManager.getCommands()).to.be.empty

    it 'allows to add commands', ->
      command = new TestCommand()
      @processManager.trigger command
      expect(@processManager.getCommands()).to.eql [command]
