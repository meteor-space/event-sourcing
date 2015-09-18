class Space.eventSourcing.Snapshotter extends Space.Object

  ERRORS:
    noSnapshotFound: (id) -> new Error "No snapshot was found for aggregate <#{id}>"

  _collection: null
  _versionFrequency: 0

  constructor: (config) ->
    @_collection = config.collection
    @_versionFrequency = config.versionFrequency

  makeSnapshotOf: (aggregate) ->
    id = aggregate.getId().toString()
    currentVersion = aggregate.getVersion()
    data = @_collection.findOne _id: id

    if data? and data.snapshot.version <= currentVersion - @_versionFrequency
      # Update existing snapshot of this aggregate
      @_collection.update {_id: id}, $set: snapshot: aggregate.getSnapshot()
    else if !data?
      # Insert first snapshot of this aggregate
      @_collection.insert _id: id, snapshot: aggregate.getSnapshot()

  getSnapshotOf: (Type, id) ->
    id = id.toString()
    record = @_collection.findOne(_id: id)
    if record?
      return Type.createFromSnapshot record.snapshot
    else
      throw @ERRORS.noSnapshotFound(id)
