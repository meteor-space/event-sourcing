
class Space.eventSourcing.CommitStore extends Space.Object

  @type 'Space.eventSourcing.CommitStore'

  dependencies:
    commits: 'Space.eventSourcing.Commits'
    commitPublisher: 'Space.eventSourcing.CommitPublisher'
    configuration: 'configuration'
    log: 'log'

  add: (changes, sourceId, expectedVersion) ->
    @log.debug(@_logMsg("Adding commit for #{changes.aggregateType}<#{sourceId}>
          expected at version #{expectedVersion}"))

    # only continue if there actually ARE changes to be added
    if !changes? or !changes.events or changes.events.length is 0 then return
    if !changes.commands? then changes.commands = []

    # fetch last inserted batch to get the current version
    lastCommit = @_getLastCommit(sourceId)
    if lastCommit?
      # take version of last existing commit
      currentVersion = lastCommit.version
    else
      # first time being saved, so start at 0
      currentVersion = 0
    if currentVersion isnt expectedVersion
      throw new Space.eventSourcing.CommitConcurrencyException(
        sourceId,
        expectedVersion,
        currentVersion
      )
    else
      newVersion = currentVersion + 1
      @_setEventVersion(event, newVersion) for event in changes.events

      # serialize events and commands
      serializedChanges = events: [], commands: []
      for event in changes.events
        serializedChanges.events.push type: event.typeName(), data: event.toData()
      for command in changes.commands
        serializedChanges.commands.push type: command.typeName(), data: command.toData()

      commit = {
        sourceId: sourceId.toString()
        version: newVersion
        changes: serializedChanges
        insertedAt: new Date()
        eventTypes: @_getEventTypes(changes.events)
        sentBy: @configuration.appId
        receivers: [{ appId: @configuration.appId, receivedAt: new Date }]
      }

      # insert commit with next version
      @log.debug(@_logMsg("Inserting commit"), commit)
      try
        commitId = @commits.insert commit
      catch error
        if (error.code == 11000)
          # A commit for this aggregate version already exists
          # Re-query for the changed state
          lastCommit = @_getLastCommit(sourceId)
          throw new Space.eventSourcing.CommitConcurrencyException(
            sourceId,
            expectedVersion,
            lastCommit.version
          )
        else
          throw error

      @commitPublisher.publishCommit
        _id: commitId,
        changes: {
          events: changes.events
          commands: changes.commands
        }

  getEvents: (sourceId, versionOffset=1) ->
    events = []
    withVersionOffset = {
      sourceId: sourceId.toString()
      version: $gte: versionOffset
    }
    sortByVersion = sort: [['version', 'asc']]
    commits = @commits.find withVersionOffset, sortByVersion
    return @_parseEventsFromCommits commits

  getAllEvents: -> @_parseEventsFromCommits @commits.find()

  _parseEventsFromCommits: (commits) ->
    events = []
    commits.forEach (commit) =>
      for event in commit.changes.events
        try
          event = Space.resolvePath(event.type).fromData(event.data)
        catch error
          throw new Error "while parsing commit\nevent:#{event}\nerror:#{error}"
        events.push event
    return events

  _setEventVersion: (event, version) -> event.version = version

  _getEventTypes: (events) -> events.map (event) -> event.typeName()

  _getLastCommit: (sourceId) ->
    @commits.findOne(
      { sourceId: sourceId.toString() }, # selector
      { sort: [['version', 'desc']], fields: { version: 1 } } # options
    )

  _logMsg: (message) ->
    "#{@configuration.appId}: #{this}: #{message}"
