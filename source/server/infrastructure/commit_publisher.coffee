
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
  _processingTimer: null

  startPublishing: ->
    appId = @configuration.appId
    if not appId? then throw new Error "#{this}: You have to specify an appId"
    notReceivedYet = { 'receivers.appId': { $nin: [appId] }}
    @log.info "#{this}: Start publishing commits for app #{appId}"
    # Save the observe handle for stopping
    @_publishHandle = @commits.find(notReceivedYet).observe {
      added: (commit) =>
        # Find and lock the event, so only one app instance publishes it
        lockedCommit = @commits.findAndModify({
          query: $and: [_id: commit._id, notReceivedYet]
          update: $push: { receivers: { appId: appId, receivedAt: new Date() } }
        })
        # Only publish the event if this process was the one that locked it
        @publishCommit(@_parseCommit(lockedCommit)) if lockedCommit?
    }

  stopPublishing: ->
    @log.info "#{this}: Stop publishing commits for app #{@configuration.appId}"
    @_publishHandle?.stop()

  publishCommit: (commit) =>
    try
      @_setProcessingTimeout(commit)
      for event in commit.changes.events
        @log.info "#{this}: Publishing event #{event.typeName()}\n", event
        @eventBus.publish event
      for command in commit.changes.commands
        @log.info "#{this}: Publishing command #{command.typeName()}\n", command
        @commandBus.send command
      @_markAsProcessed(commit)
    catch error
      @_failCommitProcessingAttempt(commit)
      throw new Error "while publishing:\n
        #{JSON.stringify(commit)}\n
        error:#{error.message}\n
        stack:#{error.stack}"


  _setProcessingTimeout: (commit) ->
    @_processingTimer = @meteor.setTimeout (=>
      @log.error "#{this}: Commit #{commit._id} processing timed out\n"
      @_failCommitProcessingAttempt(commit)
    ), @configuration.eventSourcing.commitProcessing.timeout

  _parseCommit: (commit) ->
    events = []
    commands = []
    # Only parse events that can be handled by this app
    for event in commit.changes.events
      events.push(@_parseMessage(event)) if @_supportsEjsonType event
    # Only parse commands that can be handled by this app
    for command in commit.changes.commands
      type = JSON.parse(command).$type
      commands.push(@_parseMessage(command)) if @commandBus.hasHandlerFor type

    commit.changes.events = events
    commit.changes.commands = commands
    return commit

  _parseMessage: (message) ->
    try
      return @ejson.parse(message)
    catch error
      throw new Error "while parsing \m:#{message}\nerror:#{error}"

  _supportsEjsonType: (message) -> @ejson._getTypes()[JSON.parse(message).$type]?

  _failCommitProcessingAttempt: (commit) ->
    appId = @configuration.appId
    @commits.update(
      { _id: commit._id, 'receivers.appId': appId },
      { $set: { 'receivers.$.failedAt': new Date() } }
    )

  _markAsProcessed: (commit) ->
    appId = @configuration.appId
    @meteor.clearTimeout(@_processingTimer)
    @commits.update(
      { _id: commit._id, 'receivers.appId': appId },
      { $set: { 'receivers.$.processedAt': new Date() } }
    )
    @log.info("Processing complete for commit #{commit._id} in app #{@configuration.appId}", commit)
