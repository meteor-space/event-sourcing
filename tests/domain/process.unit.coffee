
Process = Space.eventSourcing.Process
Event = Space.domain.Event

describe "Space.eventSourcing.Process", ->

  class TestCommand

  class TestProcess extends Process
    eventCorrelationProperty: 'testProcessId'
    handlers: -> 'Space.domain.Event': handler

  describe 'class', ->

    it 'extends aggregate root', ->
      expect(Process).to.extend Space.eventSourcing.Aggregate

  describe 'working with commands', ->

    beforeEach ->
      @processId = new Guid()
      @event = event = new Event sourceId: @processId, version: 1
      @handler = handler = sinon.spy()

    it 'generates no commands by default', ->
      @process = new TestProcess @processId
      expect(@process.getCommands()).to.be.empty

    it 'can be passed a Guid for the id', ->
      @process = new TestProcess @processId
      expect(@process.getId()).to.be.instanceOf(Guid)

    it 'can be passed a string for the id', ->
      @process = new TestProcess '123'
      expect(@process.getId()).to.equal '123'

    it 'can define commands to be triggered later, including metadata containing the instance id as a string for the purpose of correlating events published externally', ->
      @process = new TestProcess @processId
      command = new TestCommand()
      meta = {};
      meta[TestProcess::eventCorrelationProperty] = @process.getId().toString();
      decoratedCommand = _.extend({}, command, {meta})
      @process.trigger command
      expect(@process.getCommands()).to.eql [decoratedCommand]
