
class Space.eventSourcing.CommitStore extends Space.Object

  @type 'Space.eventSourcing.CommitStore'

  dependencies:
    commits: 'Space.eventSourcing.Commits'
    commitPublisher: 'Space.eventSourcing.CommitPublisher'
    configuration: 'configuration'
    log: 'log'

  add: (changes, sourceId, expectedVersion) ->
    @log.info(@_logMsg("Adding commit for #{changes.aggregateType}<#{sourceId}>
          expected at version #{expectedVersion}"))

    # only continue if there actually ARE changes to be added
    if !changes? or !changes.events or changes.events.length is 0 then return
    if !changes.commands? then changes.commands = []

    # fetch last inserted batch to get the current version
    lastCommit = @commits.findOne(
      { sourceId: sourceId.toString() }, # selector
      { sort: [['version', 'desc']], fields: { version: 1 } } # options
    )
    if lastCommit?
      # take version of last existing commit
      currentVersion = lastCommit.version
    else
      # the entity didnt exist before
      currentVersion = 0

    if currentVersion is expectedVersion

      newVersion = currentVersion + 1

      @_setEventVersion(event, newVersion) for event in changes.events
      # serialize events and commands
      serializedChanges = events: [], commands: []
      serializedChanges.events.push(EJSON.stringify(event)) for event in changes.events
      serializedChanges.commands.push(EJSON.stringify(command)) for command in changes.commands

      commit = {
        sourceId: sourceId.toString()
        version: newVersion
        changes: serializedChanges # insert EJSON serialized changes
        insertedAt: new Date()
        eventTypes: @_getEventTypes(changes.events)
        sentBy: @configuration.appId
        receivers: [{ appId: @configuration.appId, receivedAt: new Date }]
      }

      # insert commit with next version
      @log.info(@_logMsg("Inserting commit"), commit)
      commitId = @commits.insert commit

      @commitPublisher.publishCommit
        _id: commitId,
        changes: {
          events: changes.events
          commands: changes.commands
        }

    else

      # concurrency exception
      throw new Error "Expected entity <#{sourceId}> to be at version
                      #{expectedVersion} but was on #{currentVersion}"

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
          event = EJSON.parse(event)
        catch error
          throw new Error "while parsing commit\nevent:#{event}\nerror:#{error}"
        events.push event
    return events

  _setEventVersion: (event, version) -> event.version = version

  _getEventTypes: (events) -> events.map (event) -> event.typeName()

  _logMsg: (message) ->
    "#{@configuration.appId}: #{this}: #{message}"
