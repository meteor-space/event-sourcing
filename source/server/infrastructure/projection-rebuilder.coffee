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
    startHrTime = process.hrtime()

    @log.info(@_logMsg("Rebuilding #{projections}"))

    # Loop over all projections that should be rebuilt
    for projectionId in projections
      projection = @injector.get projectionId
      # Save backups of the real collections to restore them later and
      # override the real collections with in-memory pendants
      for collectionId in @_getCollectionIdsOfProjection(projection)
        realCollectionsBackups[collectionId] = @injector.get collectionId
        @log.debug(@_logMsg("Backed up #{collectionId}"))
        @injector.override(collectionId).to new @mongo.Collection(null)
        @log.debug(@_logMsg("Injector mapping for #{collectionId} overridden with in-memory staging collection"))


      # Tell the projection that it will be rebuilt now
      projection.enterRebuildMode()
      queue.push projection

    try
      # Loop through all events and hand them individually to all projections
      @log.debug(@_logMsg("Starting to pass events to #{projectionId} from Commit Store"))
      for event in @commitStore.getAllEvents()
        projection.on(event, true) for projection in queue
      @log.debug(@_logMsg("Finished passing events to #{projectionId}"))

      # Update the real collection data with the in-memory versions
      for collectionId, realCollection of realCollectionsBackups
        inMemoryCollection = @injector.get(collectionId)
        inMemoryData = inMemoryCollection.find().fetch()
        realCollection.remove {}
        @log.debug(@_logMsg("Removed existing docs from #{collectionId}"))
        if inMemoryData.length
          realCollection.batchInsert inMemoryData
          @log.debug(@_logMsg("Rebuilt staged collection batch inserted into #{collectionId}"))
        else
          @log.info(@_logMsg("No data to insert after replaying events for #{collectionId}"))
        # Restore original collection and cleanup backup
        @injector.override(collectionId).to realCollection
        delete realCollectionsBackups[collectionId]
      @log.debug(@_logMsg("Restored collection injector mappings for #{projectionId}"))
    finally
      for projection in queue
        projection.exitRebuildMode()
    duration = Math.round(process.hrtime(startHrTime)[1]/1000000)
    responseMessage = "Finished rebuilding #{projections} in #{duration}ms"
    @log.info(@_logMsg(responseMessage))
    return responseMessage

  _getCollectionIdsOfProjection: (projection) ->
    collectionIds = []
    for property, id of projection.collections
      collectionIds.push(id) if projection[property]
    return collectionIds

  _logMsg: (message) ->
    "#{@configuration.appId}: #{this}: #{message}"
