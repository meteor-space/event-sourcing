
class Space.eventSourcing extends Space.Module

  @publish this, 'Space.eventSourcing'

  @commitsCollection: null
  @snapshotsCollection: null

  Configuration: Space.getenv.multi({
    eventSourcing: {
      log: {
        enabled: ['SPACE_ES_LOG_ENABLED', false, 'bool']
      }
      snapshotting: {
        enabled: ['SPACE_ES_SNAPSHOTTING_ENABLED', true, 'bool']
        frequency: ['SPACE_ES_SNAPSHOTTING_FREQUENCY', 10, 'int']
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
    @commitPublisher.startPublishing()

  onReset: ->
    @injector.get('Space.eventSourcing.Commits').remove {}
    @injector.get('Space.eventSourcing.Snapshots').remove {}

  onStop: ->
    @commitPublisher.stopPublishing()

  _setupLogging: ->
    @injector.map('Space.eventSourcing.Log').to =>
      console.log.apply(null, arguments) if @Configuration.eventSourcing.log.enabled

  _setupCommitsCollection: ->
    if Space.eventSourcing.commitsCollection?
      CommitsCollection = Space.eventSourcing.commitsCollection
    else
      commitsName = Space.getenv('SPACE_ES_COMMITS_COLLECTION_NAME', 'space_eventSourcing_commits')
      CommitsCollection = new @mongo.Collection commitsName, @_collectionOptions()
      CommitsCollection._ensureIndex { "sourceId": 1, "version": 1 }, unique: true
      Space.eventSourcing.commitsCollection = CommitsCollection
    @injector.map('Space.eventSourcing.Commits').to CommitsCollection

  _setupSnapshotting: ->
    if Space.eventSourcing.snapshotsCollection?
      SnapshotsCollection = Space.eventSourcing.snapshotsCollection
    else
      snapshotsName = Space.getenv('SPACE_ES_SNAPSHOTTING_COLLECTION_NAME', 'space_eventSourcing_snapshots')
      SnapshotsCollection = new @mongo.Collection snapshotsName, @_collectionOptions()
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
        driverOptions = { oplogUrl:  Space.getenv('SPACE_ES_COMMITS_MONGO_OPLOG_URL') }
      else
        driverOptions = {}
      mongoUrl = Space.getenv('SPACE_ES_COMMITS_MONGO_URL')
      return _driver: new @mongoInternals.RemoteCollectionDriver(mongoUrl, driverOptions)
    else
      return {}

  _externalMongo: ->
    true if Space.getenv('SPACE_ES_COMMITS_MONGO_URL', '').length > 0

  _externalMongoNeedsOplog: ->
    true if Space.getenv('SPACE_ES_COMMITS_MONGO_OPLOG_URL', '').length > 0
