class Space.eventSourcing.Projector extends Space.Object

  Dependencies: {
    publisher: 'Space.eventSourcing.CommitPublisher'
    commitStore: 'Space.eventSourcing.CommitStore'
    eventBus: 'Space.messaging.EventBus'
    injector: 'Injector'
    mongo: 'Mongo'
  }

  replay: (options) ->

    unless options.projections?
      throw new Error 'You have to provide an array of projection qualifiers.'

    # Tell commit publisher to queue up incoming requests
    @publisher.pausePublishing()

    realCollectionsBackups = {}
    projectionsToRebuild = []

    # Loop over all projections that should be rebuilt
    for projectionId in options.projections
      projection = @injector.get projectionId
      projectionsToRebuild.push projection
      # Save backups of the real collections to restore them later and
      # override the real collections with in-memory pendants
      for collectionId in @_getCollectionsOfProjection(projection)
        realCollectionsBackups[collectionId] = @injector.get collectionId
        @injector.override(collectionId).to new @mongo.Collection(null)

    # Loop through all events and hand them indiviually to all projections
    for event in @commitStore.getAllEvents()
      projection.on(event) for projection in projectionsToRebuild

    # Update the real collection data with the in-memory versions
    # for the specified projections only.
    for collectionId, realCollection of realCollectionsBackups
      inMemoryCollection = @injector.get(collectionId)
      bulkCollectionUpdate realCollection, inMemoryCollection.find().fetch()
      # Restore original collections
      @injector.override(collectionId).to realCollection

    # Tell commit publisher to continue with publishing (also the queued ones)
    @publisher.continuePublishing()

  _getCollectionsOfProjection: (projection) ->
    collectionIds = []
    for property, id of projection.Dependencies
      collectionIds.push(id) if projection[property] instanceof Mongo.Collection
    return collectionIds
