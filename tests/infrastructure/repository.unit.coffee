
{Repository} = Space.cqrs

describe 'Space.cqrs.Repository', ->

  beforeEach ->
    @commitStore =
      getEvents: sinon.stub()
      add: sinon.stub()
    @snapshotter =
      getLatestVersionOf: sinon.stub()
      makeSnapshotOf: sinon.stub()
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

  describe 'snapshotting of aggregates', ->

    describe 'saving snapshots', ->

      it 'hands over the aggregate to the snapshotter before saving', ->
        @repository.useSnapshotter @snapshotter
        aggregate = getId: -> '123'
        @repository.save aggregate, 1
        expect(@snapshotter.makeSnapshotOf).to.have.been.calledWithExactly aggregate

    describe 'finding snapshots', ->

      it 'retrieves the aggregate from the snapshotter', ->
        # Setup a fake aggregate that is returned by the snapshotter
        Aggregate = ->
        id = '123'
        version = 3
        aggregateInstance =
          replayHistory: sinon.stub()
          getVersion: -> version
        events = [{ type: 'test' }]

        @repository.useSnapshotter @snapshotter

        @snapshotter.getLatestVersionOf
                    .withArgs(Aggregate, id)
                    .returns(aggregateInstance)

        @commitStore.getEvents
                    .withArgs(id, version + 1)
                    .returns(events)

        aggregate = @repository.find Aggregate, id

        expect(aggregateInstance.replayHistory).to.have.been.calledWith events
        expect(aggregate).to.equal aggregateInstance
