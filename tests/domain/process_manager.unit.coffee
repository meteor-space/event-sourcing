
ProcessManager = Space.cqrs.ProcessManager
Event = Space.cqrs.Event

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

  describe "#handle", ->

    it 'invokes the mapped event handler', ->

      @processManager.handle @event
      expect(@handler).to.have.been.calledWithExactly @event

    it 'does not add the event as uncommitted change', ->

      @processManager.handle @event
      expect(@processManager.getEvents()).to.eql []

    it 'it does not assign the event version to the process', ->

      @processManager.handle @event
      expect(@processManager.getVersion()).not.to.equal @event.version

    it 'also accepts events that have no version', ->

      @processManager.handle new Event sourceId: '123'
      expect(@processManager.getVersion()).to.equal 0

  describe 'working with commands', ->

    it 'a processManager generates no commands by default', ->
      expect(@processManager.getCommands()).to.be.empty

    it 'allows to add commands', ->
      command = new TestCommand()
      @processManager.trigger command
      expect(@processManager.getCommands()).to.eql [command]

  describe 'working with state', ->

    it 'has no state by default', ->
      expect(@processManager.hasState()).to.be.false

    it 'can transition to a state', ->
      state = 0
      @processManager.transitionTo state
      expect(@processManager.hasState(state)).to.be.true

    it 'can be asked if it has any state at all', ->
      @processManager.transitionTo 0
      expect(@processManager.hasState()).to.be.true
