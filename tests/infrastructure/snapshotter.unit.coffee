
{Snapshotter} = Space.cqrs

describe 'Space.cqrs.Snapshotter', ->

  class TestAggregate extends Space.cqrs.Aggregate
    @toString: -> 'TestAggregate'
    @FIELDS: test: null

  beforeEach ->
    @collection = new Mongo.Collection(null)
    @versionFrequency = 2
    @snapshotter = new Snapshotter {
      collection: @collection
      versionFrequency: @versionFrequency
    }
    @aggregateId = '123'
    @aggregate = new TestAggregate @aggregateId
    @aggregate.test = 'test'

  describe 'making snapshots', ->

    it 'saves the current state of the aggregate', ->
      @aggregate._version = @versionFrequency
      @snapshotter.makeSnapshotOf @aggregate
      expect(@collection.findOne()).toMatch {
        _id: @aggregateId
        snapshot: @aggregate.getSnapshot()
      }

    it 'skips snapshot if not enough versions have passed', ->
      # Simulate a previous snapshot at version 1
      firstSnapshot = @aggregate.getSnapshot()
      @collection.insert {
        _id: @aggregateId
        snapshot: firstSnapshot
      }

      # Increase aggregate version + 1 (not enough for the frequency)
      @aggregate._version = 1
      @snapshotter.makeSnapshotOf @aggregate

      # No snapshot should have been taken!
      expect(@collection.findOne()).toMatch {
        _id: @aggregateId
        snapshot: firstSnapshot
      }

    it 'makes snapshot when enough versions have passed', ->
      # Simulate a previous snapshot at version 1
      @collection.insert {
        _id: @aggregateId
        snapshot: @aggregate.getSnapshot()
      }

      # Increase aggregate version + 2 (enough for the frequency)
      @aggregate._version = 3
      @snapshotter.makeSnapshotOf @aggregate

      # No snapshot should have been taken!
      expect(@collection.findOne()).toMatch {
        _id: @aggregateId
        snapshot: @aggregate.getSnapshot()
      }

  describe 'getting latest snapshot of aggregate', ->

    it 'creates and returns an aggregate instance based on the snapshot', ->

      # Simulate a previous snapshot at version 1
      @collection.insert {
        _id: @aggregateId
        snapshot: @aggregate.getSnapshot()
      }

      aggregate = @snapshotter.getSnapshotOf TestAggregate, @aggregateId

      expect(aggregate).to.be.instanceOf TestAggregate
      expect(aggregate.getVersion()).to.equal @aggregate.getVersion()
      expect(aggregate.getState()).to.equal @aggregate.getState()
      expect(aggregate.getSnapshot()).toMatch @aggregate.getSnapshot()
