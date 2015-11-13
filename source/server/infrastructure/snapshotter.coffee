class Space.eventSourcing.Snapshotter extends Space.Object

  @snapshotsCollection: null

  Dependencies: {
    configuration: 'Configuration'
    ejson: 'EJSON'
    injector: 'Injector'
    mongo: 'Mongo'
  }

  collection: null
  versionFrequency: 0

  onDependenciesReady: ->
    @_setupSnapshotting() if @configuration.eventSourcing.snapshotting.enabled

  _setupSnapshotting: ->
    if Snapshotter.snapshotsCollection?
      SnapshotsCollection = Snapshotter.snapshotsCollection
    else
      collectionNameEnvVar = 'SPACE_ES_SNAPSHOTTING_COLLECTION_NAME'
      collectionDefaultName = 'space_eventSourcing_snapshots'
      snapshotsName = Space.getenv collectionNameEnvVar, collectionDefaultName
      mongoConnection = @configuration.eventSourcing.mongo.connection
      SnapshotsCollection = new @mongo.Collection snapshotsName, mongoConnection
      Snapshotter.snapshotsCollection = SnapshotsCollection

    @collection = SnapshotsCollection
    @versionFrequency = @configuration.eventSourcing.snapshotting.frequency
    @injector.map('Space.eventSourcing.Snapshots').to SnapshotsCollection
    @injector.get('Space.eventSourcing.Repository').useSnapshotter this

  makeSnapshotOf: (aggregate) ->
    id = aggregate.getId().toString()
    currentVersion = aggregate.getVersion()
    data = @collection.findOne _id: id
    data?.snapshot = @ejson.parse(data.snapshot)
    snapshot = aggregate.getSnapshot()
    if data? and data.snapshot.version <= currentVersion - @versionFrequency
      # Update existing snapshot of this aggregate
      @collection.update {_id: id}, $set: snapshot: @ejson.stringify(snapshot)
    else if !data?
      # Insert first snapshot of this aggregate
      @collection.insert _id: id, snapshot: @ejson.stringify(snapshot)

  getSnapshotOf: (Type, id) ->
    record = @collection.findOne(_id: id.toString())
    if record?
      return Type.createFromSnapshot @ejson.parse(record.snapshot)
    else
      return null
