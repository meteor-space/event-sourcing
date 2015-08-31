class Space.cqrs.Snapshotter extends Space.Object

  _collection: null
  _versionFrequency: 0

  constructor: (config) ->
    @_collection = config.collection
    @_versionFrequency = config.versionFrequency

  makeSnapshotOf: (aggregate) ->
    id = aggregate.getId()
    currentVersion = aggregate.getVersion()
    data = @_collection.findOne _id: id

    if data? and data.snapshot.version <= currentVersion - @_versionFrequency
      # Update existing snapshot of this aggregate
      @_collection.update {_id: id}, $set: snapshot: aggregate.getSnapshot()
    else if !data?
      # Insert first snapshot of this aggregate
      @_collection.insert _id: id, snapshot: aggregate.getSnapshot()

  getSnapshotOf: (Type, id) ->
    return Type.createFromSnapshot @_collection.findOne(_id: id).snapshot
