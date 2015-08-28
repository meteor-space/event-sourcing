
{Snapshotter} = Space.cqrs

describe 'Space.cqrs.Snapshotter', ->

  class TestAggregate extends Space.cqrs.Aggregate
    @toString: -> 'TestAggregate'
    _test: null
    getSnapshot: -> test: @_test
    applySnapshot: (snapshot) -> @_test = snapshot.test

  beforeEach ->
    @collection = new Mongo.Collection(null)
    @snapshotter = new Snapshotter {
      collection: @collection
      versionFrequency: 2
    }
    @aggregateId = '123'
    @aggregate = new TestAggregate @aggregateId
    @aggregate.applySnapshot test: 'test'
    @aggregate._version = 1

  describe 'making snapshots', ->

    it 'saves the current state of the aggregate', ->
      @snapshotter.makeSnapshotOf TestAggregate, @aggregate
      expect(@collection.findOne()).toMatch {
        _id: @aggregateId
        type: TestAggregate.toString()
        version: 1
        snapshot: @aggregate.getSnapshot()
      }

    it 'skips snapshot if not enough versions have passed', ->
      # Simulate a previous snapshot at version 1
      @collection.insert {
        _id: @aggregateId
        type: TestAggregate.toString()
        version: 1
        snapshot: @aggregate.getSnapshot()
      }

      # Increase aggregate version + 1 (not enough for the frequency)
      @aggregate._version = 2
      @snapshotter.makeSnapshotOf TestAggregate, @aggregate

      # No snapshot should have been taken!
      expect(@collection.findOne()).toMatch {
        _id: @aggregateId
        type: TestAggregate.toString()
        version: 1 # still at version 1
        snapshot: @aggregate.getSnapshot()
      }

    it 'makes snapshot when enough versions have passed', ->
      # Simulate a previous snapshot at version 1
      @collection.insert {
        _id: @aggregateId
        type: TestAggregate.toString()
        version: 1
        snapshot: @aggregate.getSnapshot()
      }

      # Increase aggregate version + 2 (enough for the frequency)
      @aggregate._version = 3
      @snapshotter.makeSnapshotOf TestAggregate, @aggregate

      # No snapshot should have been taken!
      expect(@collection.findOne()).toMatch {
        _id: @aggregateId
        type: TestAggregate.toString()
        version: 3 # now at version 3!
        snapshot: @aggregate.getSnapshot()
      }

  describe 'getting latest snapshot of aggregate', ->

    it 'creates and returns an aggregate instance based on the snapshot', ->

      # Simulate a previous snapshot at version 1
      @collection.insert {
        _id: @aggregateId
        type: TestAggregate.toString()
        version: 2
        snapshot: @aggregate.getSnapshot()
      }

      aggregate = @snapshotter.getSnapshotOf TestAggregate, @aggregateId

      expect(aggregate).to.be.instanceOf TestAggregate
      expect(aggregate.getVersion()).to.equal 2
      expect(aggregate.getSnapshot()).toMatch @aggregate.getSnapshot()
