
class Space.eventSourcing.CommitPublisher extends Space.Object

  @type 'Space.eventSourcing.CommitPublisher'

  dependencies:
    commits: 'Space.eventSourcing.Commits'
    configuration: 'configuration'
    eventBus: 'Space.messaging.EventBus'
    commandBus: 'Space.messaging.CommandBus'
    meteor: 'Meteor'
    ejson: 'EJSON'
    log: 'log'

  _publishHandle: null
  _inProgress: {}

  startPublishing: ->
    appId = @configuration.appId
    if not appId? then throw new Error "#{this}: You have to specify an appId"
    registered = { $or: [
      { 'eventTypes': { $in: @eventBus.getHandledEventTypes() }},
      { 'commandTypes': { $in: @commandBus.getHandledCommandTypes() }},
    ]}
    notReceivedYet = { 'receivers.appId': { $nin: [appId] }};
    # Save the observe handle for stopping
    registeredAndNotReceivedYet = { $and: [ registered, notReceivedYet] }
    @_publishHandle = @commits.find(registeredAndNotReceivedYet).observe {
      added: (commit) =>
        # Find and lock the event, so only one app instance publishes it
        lockedCommit = @commits.findAndModify({
          query: $and: [_id: commit._id, registeredAndNotReceivedYet]
          update: $push: { receivers: { appId: appId, receivedAt: new Date() } }
        })
        # Only publish the event if this process was the one that locked it
        @publishChanges(@parseChanges(lockedCommit), commit._id) if lockedCommit?
    }
    @log.info @_logMsg("observing for commits via the collection")

  stopPublishing: ->
    @_publishHandle?.stop()
    @log.info @_logMsg("collection observer stopped")

  publishChanges: (changes, commitId) =>
    @_setTimeout(changes, commitId)
    try
      for event in changes.events
        @log.debug @_logMsg("publishing #{event.typeName()}"), event
        @eventBus.publish event
      for command in changes.commands
        @log.debug @_logMsg("sending #{command.typeName()}"), command
        @commandBus.send command
    catch error
      @commits.update(
        { _id: commitId, 'receivers.appId': @configuration.appId },
        { $set: { 'receivers.$.failedAt': new Date() } }
      )
      throw error
    finally
      @_clearTimeout(commitId)

    @commits.update(
      { _id: commitId, 'receivers.appId': @configuration.appId },
      { $set: { 'receivers.$.processedAt': new Date() } }
    )
    @log.debug @_logMsg("#{commitId} PROCESSED"), changes

  _setTimeout: (changes, commitId) ->
    @_inProgress[commitId] = @meteor.setTimeout (=>
      @_onTimeout(changes, commitId)
    ), @configuration.eventSourcing.commitProcessing.timeout

  _onTimeout: (changes, commitId) ->
    failedCommit = @commits.findAndModify({
      query: { $and: [
        { _id: commitId },
        { 'receivers': {
          $elemMatch: {
            appId: @configuration.appId,
            'processedAt': { $exists: false }
          }
        }}
      ]}
      update: $set: { 'receivers.$.failedAt': new Date() }
    })
    if(failedCommit)
      @log.error(@_logMsg("#{commitId} TIMED OUT"), changes)
    @_cleanupTimeout(commitId)

  _clearTimeout: (commitId) ->
    @meteor.clearTimeout(@_inProgress[commitId])
    @_cleanupTimeout(commitId)

  _cleanupTimeout: (commitId) ->
    delete @_inProgress[commitId]

  parseChanges: (commit) ->
    events = []
    commands = []
    # Only parse events that can be handled by this app
    for event in commit.changes.events
      if @_supportsEjsonType(event.type) and @eventBus.hasHandlerFor(event.type)
        EventType = Space.resolvePath(event.type)
        events.push EventType.fromData(event.data)
    # Only parse commands that can be handled by this app
    for command in commit.changes.commands
      if @_supportsEjsonType(command.type) and @commandBus.hasHandlerFor(command.type)
        CommandType = Space.resolvePath(command.type)
        commands.push CommandType.fromData(command.data)
    return { events, commands }

  _supportsEjsonType: (type) -> @ejson._getTypes()[type]?

  _logMsg: (message) ->
    "#{@configuration.appId}: #{this}: #{message}"

  # Backwards compatibility
  publishCommit: (commit) ->
    @log.warning(@_logMsg('CommitPublisher publishCommit(commit) is
      depreciated. Use publishChanges(changes, commitId)'))
    @publishChanges(commit.changes, commit._id)
