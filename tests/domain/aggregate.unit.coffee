
{Aggregate} = Space.eventSourcing
{Event, Command} = Space.messaging

describe "Space.eventSourcing.Aggregate", ->

  class TestEvent extends Event
    @type 'TestEvent'
    @fields: sourceId: String, version: Match.Integer

  class TestCommand extends Command
    @type 'TestCommand'
    @fields: targetId: String, version: Match.Integer

  class TestAggregate extends Aggregate

  beforeEach ->
    @aggregateId = '123'
    @event = event = new TestEvent sourceId: @aggregateId, version: 2
    @command = command = new TestCommand targetId: @aggregateId, version: 1
    @eventHandler = eventHandler = sinon.spy()
    @commandHandler = commandHandler = sinon.spy()
    TestAggregate::handlers = -> {
      'Space.messaging.Event': ->
      TestEvent: eventHandler
      TestCommand: commandHandler
    }
    @aggregate = new TestAggregate @aggregateId

  # =========== CONSTRUCTION ============ #

  describe 'construction', ->

    it 'requires an id on creation', ->
      expect(-> new Aggregate()).to.throw Aggregate::ERRORS.guidRequired

    it 'makes the id publicly available', ->
      id = '123'
      aggregate = new Aggregate id
      expect(aggregate.getId()).to.equal id

    it 'initializes uncommitted changes to empty array', ->
      aggregate = new Aggregate '123'
      expect(aggregate.getEvents()).to.eql []

    it 'sets the initial version to 0', ->
      aggregate = new Aggregate '123'
      expect(aggregate.getVersion()).to.eql 0

    it 'can be created by providing a command', ->
      aggregate = new TestAggregate @command
      expect(aggregate.getId()).to.equal @command.targetId
      expect(@commandHandler).to.have.been.calledWithExactly @command

  # =========== RECORDING EVENTS =========== #

  describe "#record", ->

    it 'handles the given event', ->
      @aggregate.record @event
      expect(@eventHandler).to.have.been.calledWithExactly @event

    it 'pushes the event into the events array', ->
      @aggregate.record @event
      expect(@aggregate.getEvents()).to.eql [@event]

    it 'only takes domain events', ->
      event = type: 'Test', aggregateId: 'bla'
      expect(=> @aggregate.record(event)).to.throw Aggregate::ERRORS.domainEventRequired

    it 'does not throw error if missing handler for event', ->
      event = new Event sourceId: '123'
      aggregate = new Aggregate '123'
      error = Aggregate::ERRORS.cannotHandleMessage + event.typeName()
      expect(-> aggregate.record event).not.to.throw error

    it 'does not push the event into the events array if something fails', ->
      expect(=> @aggregate.record()).to.throw Error
      expect(=> @aggregate.record 'unknownEvent', {}).to.throw Error
      expect(@aggregate.getEvents()).to.eql []

  # ========== REPLAYING HISTORIC EVENTS ========== #

  describe "#replay", ->

    it 'invokes the mapped event handler', ->
      @aggregate.replay @event
      expect(@eventHandler).to.have.been.calledWithExactly @event

    it 'does not push the event into the events array', ->
      @aggregate.replay @event
      expect(@aggregate.getEvents()).to.eql []

    it 'throws error when the event is not a domain event', ->
      aggregate = @aggregate
      expect(-> aggregate.replay()).to.throw Aggregate::ERRORS.domainEventRequired
      expect(-> aggregate.replay({})).to.throw Aggregate::ERRORS.domainEventRequired

    it 'it assigns the event version to the aggregate', ->
      @aggregate.replay @event
      expect(@aggregate.getVersion()).to.equal @event.version

    it 'also accepts events that have no version', ->
      @aggregate.replay new Event sourceId: @aggregateId
      expect(@aggregate.getVersion()).to.equal 0

    it 'only replays events that have the right source id', ->
      event = new Event sourceId: 'otherId'
      expect(=> @aggregate.replay event).to.throw Aggregate::ERRORS.invalidEventSourceId

  # ========== HANDLING EVENTS AND COMMANDS ========== #

  describe "#handle", ->

    it 'invokes the mapped event handler', ->
      @aggregate.handle @event
      expect(@eventHandler).to.have.been.calledWithExactly @event

    it 'does not push the event into the events array', ->
      @aggregate.handle @event
      expect(@aggregate.getEvents()).to.eql []

    it 'it does not assign the event version to the aggregate', ->
      @aggregate.handle @event
      expect(@aggregate.getVersion()).not.to.equal @event.version

    it 'also accepts events that have no version', ->
      @aggregate.handle new Event sourceId: '123'
      expect(@aggregate.getVersion()).to.equal 0

    it 'accepts events with different source id', ->
      @event.sourceId = 'different'
      expect(=> @aggregate.handle @event).not.to.throw Error

    it 'accepts commands as well', ->
      @aggregate.handle @command
      expect(@commandHandler).to.have.been.calledWithExactly @command

  # ========== WORKING WITH EVENT HISTORY ========== #

  describe '#isHistory', ->

    it 'checks if the given param is of type array', ->
      aggregate = new Aggregate '123'
      expect(aggregate.isHistory []).to.be.true

  describe 'replaying history', ->

    class Created extends Event
      @type 'Created'

    class SomethingChanged extends Event
      @type 'SomethingChanged'

    class ChangedAgain extends Event
      @type 'ChangedAgain'

    it 'replays given historic events on the aggregate', ->

      id = '123'
      aggregate = new Aggregate id

      replaySpy = sinon.stub aggregate, 'replay'

      history = [
        new Created sourceId: id, version: 1
        new SomethingChanged sourceId: id, version: 2
        new ChangedAgain sourceId: id, version: 3
      ]

      aggregate.replayHistory history

      expect(replaySpy).to.have.been.calledThrice
      expect(replaySpy).to.have.been.calledWithExactly history[0]
      expect(replaySpy).to.have.been.calledWithExactly history[1]
      expect(replaySpy).to.have.been.calledWithExactly history[2]

    it 'can create aggregate instance by providing an array of events', ->
      aggregate = TestAggregate.createFromHistory [@event]
      expect(aggregate.getId()).to.equal @event.sourceId
      expect(@eventHandler).to.have.been.calledWithExactly @event

  describe 'working with state', ->

    class StateChangingEvent extends Space.messaging.Event
      @toString: -> 'StateChangingEvent'
      typeName: -> 'StateChangingEvent'

    class StateAggregate extends Space.eventSourcing.Aggregate
      handlers: -> 'StateChangingEvent': (event) -> @_state = event.state

    it 'has no state by default', ->
      expect(@aggregate.hasState()).to.be.false

    it 'can transition to a state', ->
      expectedState = 'test'
      event = new StateChangingEvent()
      event.state = expectedState
      aggregate = new StateAggregate '123'
      aggregate.handle event
      expect(aggregate.hasState(expectedState)).to.be.true
