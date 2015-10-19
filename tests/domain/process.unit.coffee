
Process = Space.eventSourcing.Process
Event = Space.messaging.Event

describe "Space.eventSourcing.Process", ->

  class TestCommand

  beforeEach ->
    @event = event = new Event sourceId: '123', version: 1
    @handler = handler = sinon.spy()

    class TestProcess extends Process
      handlers: -> 'Space.messaging.Event': handler

    @processManager = new TestProcess '123'

  it 'extends aggregate root', ->
    expect(Process).to.extend Space.eventSourcing.Aggregate

  describe 'working with commands', ->

    it 'a process generates no commands by default', ->
      expect(@processManager.getCommands()).to.be.empty

    it 'allows to add commands', ->
      command = new TestCommand()
      @processManager.trigger command
      expect(@processManager.getCommands()).to.eql [command]
