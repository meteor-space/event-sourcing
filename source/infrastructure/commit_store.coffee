
class Space.cqrs.CommitStore

  Dependencies:
    commits: 'Space.cqrs.Commits'
    publisher: 'Space.cqrs.CommitPublisher'

  add: (changes, sourceId, expectedVersion) ->

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

      # serialize events and commands
      serializedChanges = events: [], commands: []
      serializedChanges.events.push(EJSON.stringify(event)) for event in changes.events
      serializedChanges.commands.push(EJSON.stringify(command)) for command in changes.commands

      # insert commit with next version
      commit =
        sourceId: sourceId.toString()
        version: newVersion
        changes: serializedChanges # insert EJSON serialized changes
        isPublished: false
        insertedAt: new Date()

      commit._id = @commits.insert commit
      commit.changes = changes # dont publish serialized changes

      @publisher.publishCommit commit

    else

      # concurrency exception
      throw new Error "Expected entity <#{sourceId}> to be at version
                      #{expectedVersion} but was on #{currentVersion}"

  getEvents: (sourceId) ->

    events = []

    commits = @commits.find(
      { sourceId: sourceId.toString() }, # selector
      { sort: [['version', 'asc']] } # options
    )

    commits.forEach (commit) =>

      for event in commit.changes.events
        try
          event = EJSON.parse(event)
        catch error
          throw new Error "while parsing commit\nevent:#{event}\nerror:#{error}"
        event.version = commit.version
        events.push event

    return events
