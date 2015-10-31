
class Space.eventSourcing extends Space.Module

  @publish this, 'Space.eventSourcing'

  @commitsCollection: null
  @snapshotsCollection: null

  Configuration: {
    eventSourcing: {
      logging: {
        enabled: false
        writeStream: console
      }
      commits: {
        mongoUrl: null
        mongoOplogUrl: null
        collectionName: 'space_eventSourcing_commits'
        processingTimeout: 10000
      }
      snapshotting: {
        enabled: true
        frequency: 10
        collectionName: 'space_eventSourcing_snapshots'
      }
    }
  }

  RequiredModules: ['Space.messaging']

  Dependencies: {
    mongo: 'Mongo'
    mongoInternals: 'MongoInternals'
  }

  Singletons: [
    'Space.eventSourcing.CommitPublisher'
    'Space.eventSourcing.Repository'
  ]

  afterInitialize: ->
    commits = @Configuration.eventSourcing.commits
    snapshotting = @Configuration.eventSourcing.snapshotting
    logging = @Configuration.eventSourcing.logging

    # Setup distributed commits collection
    collectionOptions = {}
    if commits.mongoUrl?
      isOplogDefined = commits.mongoOplogUrl and commits.mongoOplogUrl.length > 1
      driverOptions = if isOplogDefined then oplogUrl: commits.mongoOplogUrl else {}
      collectionOptions = {
        _driver: new @mongoInternals.RemoteCollectionDriver(
          commits.mongoUrl, driverOptions
        )
      }
    if Space.eventSourcing.commitsCollection?
      CommitsCollection = Space.eventSourcing.commitsCollection
    else
      CommitsCollection = new @mongo.Collection commits.collectionName, collectionOptions
      CommitsCollection._ensureIndex { "sourceId": 1, "version": 1 }, unique: true
      Space.eventSourcing.commitsCollection = CommitsCollection

    # Setup snapshotting
    if snapshotting.enabled?

      if Space.eventSourcing.snapshotsCollection?
        SnapshotsCollection = Space.eventSourcing.snapshotsCollection
      else
        SnapshotsCollection = new @mongo.Collection(
          snapshotting.collectionName, collectionOptions
        )
        Space.eventSourcing.snapshotsCollection = SnapshotsCollection
      snapshotter = new Space.eventSourcing.Snapshotter {
        collection: SnapshotsCollection,
        versionFrequency: snapshotting.frequency
      }

    @injector.map('Space.eventSourcing.Commits').to CommitsCollection
    @injector.map('Space.eventSourcing.Snapshots').to SnapshotsCollection
    @injector.map('Space.eventSourcing.Projector').asSingleton()
    @injector.map('Space.eventSourcing.Log').to ->
      console.log.apply(null, arguments) if logging.enabled
    @commitPublisher = @injector.get('Space.eventSourcing.CommitPublisher')
    @injector.get('Space.eventSourcing.Repository').useSnapshotter snapshotter

  onStart: -> @commitPublisher.startPublishing()

  onReset: ->
    @injector.get('Space.eventSourcing.Commits').remove {}
    @injector.get('Space.eventSourcing.Snapshots').remove {}

  onStop: -> @commitPublisher.stopPublishing()
