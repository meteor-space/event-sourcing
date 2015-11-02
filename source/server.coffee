
class Space.eventSourcing extends Space.Module

  @publish this, 'Space.eventSourcing'

  @commitsCollection: null
  @snapshotsCollection: null

  Configuration: Space.getenv.multi({
    eventSourcing: {
      log: {
        enabled: ['SPACE_ES_LOG_ENABLED', true, 'bool']
      }
      commits: {
        mongoUrl: ['SPACE_ES_COMMITS_MONGO_URL', '', 'string']
        mongoOplogUrl: ['SPACE_ES_COMMITS_MONGO_OPLOG_URL', '', 'string']
        collectionName: ['SPACE_ES_COMMITS_COLLECTION_NAME', 'space_eventSourcing_commits', 'string']
        processingTimeout: ['SPACE_ES_COMMITS_PROCESSING_TIMEOUT', 1000, 'int']
      }
      snapshotting: {
        enabled: ['SPACE_ES_SNAPSHOTTING_ENABLED', true, 'bool']
        frequency: ['SPACE_ES_SNAPSHOTTING_FREQUENCY', 10, 'int']
        collectionName: ['SPACE_ES_SNAPSHOTTING_COLLECTION_NAME', 'space_eventSourcing_snapshots', 'string']
      }
    }
  })

  RequiredModules: ['Space.messaging']

  Dependencies: {
    mongo: 'Mongo'
    mongoInternals: 'MongoInternals'
  }

  Singletons: [
    'Space.eventSourcing.CommitPublisher'
    'Space.eventSourcing.Repository'
    'Space.eventSourcing.Projector'
  ]

  beforeInitialize: ->
    # Right now logging is not optional, and hard coded to output to console, but the Config API included a switch and writeStream
    @_setupLogging() # if @Configuration.eventSourcing.log.enabled

  afterInitialize: ->

    @_setupCommitsCollection()
    @_setupSnapshotting() if @Configuration.eventSourcing.snapshotting.enabled
    @commitPublisher = @injector.get('Space.eventSourcing.CommitPublisher')

  onStart: ->
    console.log('onStart')
    @commitPublisher.startPublishing()

  onReset: ->
    console.log('onReset')
    @injector.get('Space.eventSourcing.Commits').remove {}
    @injector.get('Space.eventSourcing.Snapshots').remove {}

  onStop: ->
    @commitPublisher.stopPublishing()
    console.log('onStop')

  _setupLogging: ->
    @injector.map('Space.eventSourcing.Log').to =>
      console.log.apply(null, arguments) if @Configuration.eventSourcing.log.enabled

  _setupCommitsCollection: ->
    if Space.eventSourcing.commitsCollection?
      CommitsCollection = Space.eventSourcing.commitsCollection
    else
      CommitsCollection = new @mongo.Collection @Configuration.eventSourcing.commits.collectionName, @_collectionOptions()
      CommitsCollection._ensureIndex { "sourceId": 1, "version": 1 }, unique: true
      Space.eventSourcing.commitsCollection = CommitsCollection
    @injector.map('Space.eventSourcing.Commits').to CommitsCollection

  _setupSnapshotting: ->
    if Space.eventSourcing.snapshotsCollection?
      SnapshotsCollection = Space.eventSourcing.snapshotsCollection
    else
      SnapshotsCollection = new @mongo.Collection @Configuration.eventSourcing.snapshotting.collectionName, @_collectionOptions()
      SnapshotsCollection._ensureIndex { "snapshot.state": 1, "snapshot.version": 1 }, unique: true
      Space.eventSourcing.snapshotsCollection = SnapshotsCollection
    snapshotter = new Space.eventSourcing.Snapshotter {
      collection: SnapshotsCollection,
      versionFrequency: @Configuration.eventSourcing.snapshotting.frequency
    }
    @injector.map('Space.eventSourcing.Snapshots').to SnapshotsCollection
    @injector.get('Space.eventSourcing.Repository').useSnapshotter snapshotter


  _collectionOptions: ->
    if @_externalMongo()
      if @_externalMongoNeedsOplog()
        driverOptions = { oplogUrl:  @Configuration.eventSourcing.commits.mongoOplogUrl }
      else
        driverOptions = {}
      return { _driver: new @mongoInternals.RemoteCollectionDriver  @Configuration.eventSourcing.commits.mongoUrl, driverOptions }
    else
      return {}

  _externalMongo: ->
    true if @Configuration.eventSourcing.commits.mongoUrl?.length > 0

  _externalMongoNeedsOplog: ->
    true if @Configuration.eventSourcing.commits.mongoOplogUrl?.length > 0