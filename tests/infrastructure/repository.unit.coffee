
{Repository} = Space.cqrs

describe 'Space.cqrs.Repository', ->

  beforeEach ->
    @commitStore =
      getEvents: sinon.stub()
      add: sinon.stub()
    @repository = new Repository()
    @repository.commitStore = @commitStore

  it 'defines its dependencies correctly', ->
    expect(Repository).to.dependOn
      commitStore: 'Space.cqrs.CommitStore'

  describe '#find', ->

    it 'returns an aggregate instance with the events from the store', ->

      instance = {}
      Aggregate = sinon.stub()
      Aggregate.returns instance
      id = '123'
      events = [{ type: 'test' }]
      @commitStore.getEvents.returns events
      aggregate = @repository.find Aggregate, id

      expect(Aggregate).to.have.been.calledWithNew
      expect(Aggregate).to.have.been.calledWithExactly id, events
      expect(aggregate).to.equal instance

    it 'returns null if no events are found', ->

      Aggregate = Space.Object.extend()
      id = '123'
      @commitStore.getEvents.returns []
      expect(@repository.find Aggregate, id).to.be.null

  describe '#save', ->

    it 'adds the events of an aggregate to the commit store', ->

      events = []
      id = '123'
      version = 1
      aggregate =
        getEvents: -> events
        getId: -> id

      @repository.save aggregate, version
      expect(@commitStore.add).to.have.been.calledWithMatch(
        { events: events, commands: [] }, id, version
      )

    it 'adds the events and commands of an process manager', ->

      events = []
      commands = []
      id = '123'
      version = 1
      aggregate =
        getEvents: -> events
        getCommands: -> commands
        getId: -> id

      @repository.save aggregate, version
      expect(@commitStore.add).to.have.been.calledWithMatch(
        { events: events, commands: commands }, id, version
      )
