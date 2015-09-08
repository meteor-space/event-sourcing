class Space.eventSourcing.Projector extends Space.Object

  Dependencies: {
    publisher: 'Space.eventSourcing.CommitPublisher'
    commitStore: 'Space.eventSourcing.CommitStore'
    eventBus: 'Space.messaging.EventBus'
    injector: 'Injector'
    mongo: 'Mongo'
  }

  replay: (options) ->

    # Rebuild all projections by default
    options.rebuildOnly ?= options.projections
    realCollectionsBackups = {}

    # Tell commit publisher to queue up incoming requests
    @publisher.pausePublishing()

    # Save backups of the real collections to restore them later and
    # override the real collections with in-memory pendants
    for collectionId in options.projections
      realCollectionsBackups[collectionId] = @injector.get collectionId
      @injector.override(collectionId).to new @mongo.Collection(null)

    # Retrieve and re-publish all events in the commit store
    @eventBus.publish(event) for event in @commitStore.getAllEvents()

    # Update the real collection data with the in-memory versions
    # for the specified projections only.
    for collectionId in options.rebuildOnly
      inMemoryCollection = @injector.get(collectionId)
      realCollection = realCollectionsBackups[collectionId]
      bulkCollectionUpdate realCollection, inMemoryCollection.find().fetch()

    # Restore all original collections
    for collectionId in options.projections
      @injector.override(collectionId).to realCollectionsBackups[collectionId]

    # Tell commit publisher to continue with publishing (also the queued ones)
    @publisher.continuePublishing()
