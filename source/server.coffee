
class Space.eventSourcing extends Space.Module

  @publish this, 'Space.eventSourcing'

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
    'Space.eventSourcing.Snapshotter'
  ]

  afterInitialize: ->
    commits = @Configuration.eventSourcing.commits
    snapshotting = @Configuration.eventSourcing.snapshotting
    logging = @Configuration.eventSourcing.logging

    driverOptions = if commits.mongoOplogUrl and commits.mongoOplogUrl.length > 1 then { oplogUrl: commits.mongoOplogUrl } else {}
    collectionOptions = if commits.mongoUrl? then { _driver: new @mongoInternals.RemoteCollectionDriver commits.mongoUrl, driverOptions } else {}
    CommitsCollection = new @mongo.Collection commits.collectionName, collectionOptions
    CommitsCollection._ensureIndex { "sourceId": 1, "version": 1 }, unique: true
    SnapshotsCollection = if snapshotting.enabled? then new @mongo.Collection snapshotting.collectionName, collectionOptions
    snapshotter = new Space.eventSourcing.Snapshotter { collection: SnapshotsCollection, versionFrequency: snapshotting.frequency }

    @injector.map('Space.eventSourcing.Commits').to CommitsCollection
    @injector.map('Space.eventSourcing.Snapshots').to SnapshotsCollection
    @injector.map('Space.eventSourcing.Projector').asSingleton()
    @injector.map('Space.eventSourcing.Log').to -> console.log.apply(null, arguments) if logging.enabled
    @commitPublisher = @injector.get('Space.eventSourcing.CommitPublisher')
    @injector.get('Space.eventSourcing.Repository').useSnapshotter snapshotter

  onStart: -> @commitPublisher.startPublishing()

  onReset: ->
    @injector.get('Space.eventSourcing.Commits').remove {}
    @injector.get('Space.eventSourcing.Snapshots').remove {}

  onStop: -> @commitPublisher.stopPublishing()
