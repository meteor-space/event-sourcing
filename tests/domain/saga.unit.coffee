
Saga = Space.cqrs.Saga

describe "#{Saga}", ->

  class TestCommand
    type: 'TestCommand'

  beforeEach ->
    @saga = new Saga '123'

  it 'extends aggregate root', ->

    expect(Saga.__super__.constructor).to.equal Space.cqrs.Aggregate

  describe 'working with commands', ->

    it 'a saga generates no commands by default', ->
      expect(@saga.getCommands()).to.be.empty

    it 'allows to add commands', ->
      command = new TestCommand()
      @saga.trigger command

      expect(@saga.getCommands()).to.eql [command]

  describe 'working with state', ->

    it 'has no state by default', ->
      expect(@saga.hasState()).to.be.false

    it 'can transition to a state', ->
      state = 0
      @saga.transitionTo state

      expect(@saga.hasState(state)).to.be.true

    it 'can be asked if it has any state at all', ->
      @saga.transitionTo 0

      expect(@saga.hasState()).to.be.true