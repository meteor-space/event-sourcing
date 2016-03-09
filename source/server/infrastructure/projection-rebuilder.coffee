class Space.eventSourcing.ProjectionRebuilder extends Space.Object

  @type 'Space.eventSourcing.ProjectionRebuilder'

  dependencies: {
    commitStore: 'Space.eventSourcing.CommitStore'
    configuration: 'configuration'
    injector: 'Injector'
    mongo: 'Mongo'
    log: 'log'
  }

  rebuild: (projections, options) ->

    unless projections?
      throw new Error 'You have to provide an array of projection qualifiers.'

    realCollectionsBackups = {}
    queue = []

    # Loop over all projections that should be rebuilt
    for projectionId in projections
      projection = @injector.get projectionId
      # Save backups of the real collections to restore them later and
      # override the real collections with in-memory pendants
      for collectionId in @_getCollectionIdsOfProjection(projection)
        realCollectionsBackups[collectionId] = @injector.get collectionId
        @injector.override(collectionId).to new @mongo.Collection(null)

      # Tell the projection that it will be rebuilt now
      projection.enterRebuildMode()
      queue.push projection

    # Loop through all events and hand them individually to all projections
    for event in @commitStore.getAllEvents()
      projection.on(event, true) for projection in queue

    # Update the real collection data with the in-memory versions
    # for the specified projections only.
    for collectionId, realCollection of realCollectionsBackups
      inMemoryCollection = @injector.get(collectionId)
      inMemoryData = inMemoryCollection.find().fetch()
      realCollection.remove {}
      if inMemoryData.length
        realCollection.batchInsert inMemoryData
      else
        @log.warning(@_logMsg("No data to insert after replaying events for #{collectionId}"))
      # Restore original collections
      @injector.override(collectionId).to realCollection

    for projection in queue
      projection.exitRebuildMode()

  _getCollectionIdsOfProjection: (projection) ->
    collectionIds = []
    for property, id of projection.collections
      collectionIds.push(id) if projection[property]
    return collectionIds

  _logMsg: (message) ->
    "#{@configuration.appId}: #{this}: #{message}"
