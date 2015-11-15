class Space.eventSourcing.Projector extends Space.Object

  @type 'Space.eventSourcing.Projector'

  dependencies: {
    commitStore: 'Space.eventSourcing.CommitStore'
    injector: 'Injector'
    mongo: 'Mongo'
  }

  replay: (options) ->

    unless options.projections?
      throw new Error 'You have to provide an array of projection qualifiers.'

    realCollectionsBackups = {}
    projectionsToRebuild = []

    # Loop over all projections that should be rebuilt
    for projectionId in options.projections
      projection = @injector.get projectionId
      # Save backups of the real collections to restore them later and
      # override the real collections with in-memory pendants
      for collectionId in @_getCollectionIdsOfProjection(projection)
        realCollectionsBackups[collectionId] = @injector.get collectionId
        @injector.override(collectionId).to new @mongo.Collection(null)

      # Tell the projection that it will be replayed now
      projection.enterReplayMode()
      projectionsToRebuild.push projection

    # Loop through all events and hand them indiviually to all projections
    for event in @commitStore.getAllEvents()
      projection.on(event, true) for projection in projectionsToRebuild

    # Update the real collection data with the in-memory versions
    # for the specified projections only.
    for collectionId, realCollection of realCollectionsBackups
      inMemoryCollection = @injector.get(collectionId)
      inMemoryData = inMemoryCollection.find().fetch()
      realCollection.remove {}
      if inMemoryData.length
        realCollection.batchInsert inMemoryData
      else
        throw new Error "No data to insert after replaying projection for #{collectionId}"
      # Restore original collections
      @injector.override(collectionId).to realCollection

    for projection in projectionsToRebuild
      projection.exitReplayMode()

  _getCollectionIdsOfProjection: (projection) ->
    collectionIds = []
    for property, id of projection.collections
      collectionIds.push(id) if projection[property]
    return collectionIds
