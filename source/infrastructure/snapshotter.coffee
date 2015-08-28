class Space.cqrs.Snapshotter extends Space.Object

  _collection: null
  _versionFrequency: 0

  constructor: (config) ->
    @_collection = config.collection
    @_versionFrequency = config.versionFrequency

  makeSnapshotOf: (Type, aggregate) ->
    id = aggregate.getId()
    currentVersion = aggregate.getVersion()
    snapshot = @_collection.findOne _id: id

    if snapshot? and snapshot.version <= currentVersion - @_versionFrequency
      # Update existing snapshot of this aggregate
      @_collection.update {_id: id}, $set: {
        version: currentVersion
        snapshot: aggregate.getSnapshot()
      }
    else if !snapshot?
      # Insert first snapshot of this aggregate
      @_collection.insert {
        _id: id
        type: Type.toString()
        version: currentVersion
        snapshot: aggregate.getSnapshot()
      }

  getSnapshotOf: (Type, id) ->
    data = @_collection.findOne _id: id
    aggregate = new Type(id)
    aggregate._version = data.version
    aggregate.applySnapshot data.snapshot
    return aggregate
