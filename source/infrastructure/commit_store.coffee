
globalNamespace = this

class Space.cqrs.CommitStore

  @toString: -> 'Space.cqrs.CommitStore'

  @ERRORS:
    EVENT_CLASS_LOOKUP_FAILED = 'Failed to lookup event class:'

  Dependencies:
    commits: 'Space.cqrs.CommitCollection'
    publisher: 'Space.cqrs.CommitPublisher'

  constructor: -> @globalNamespace = globalNamespace

  add: (changes, sourceId, expectedVersion) ->

    # only continue if there actually ARE changes to be added
    if !changes? or !changes.events or changes.events.length is 0 then return

    if !changes.commands? then changes.commands = []

    # fetch last inserted batch to get the current version
    lastCommit = @commits.findOne(
      { sourceId: sourceId }, # selector
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

      # insert commit with next version
      commit =
        sourceId: sourceId
        version: newVersion
        changes: changes
        isPublished: false

      commit._id = @commits.insert commit
      @publisher.publishCommit commit

    else

      # concurrency exception
      throw new Error "Expected entity <#{sourceId}> to be at version
                      #{expectedVersion} but was on #{currentVersion}"

  getEvents: (sourceId) ->

    events = []

    commits = @commits.find(
      { sourceId: sourceId }, # selector
      { sort: [['version', 'asc']] } # options
    )

    commits.forEach (commit) =>

      for event in commit.changes.events
        event.version = commit.version
        eventClass = @_lookupClass event.type

        events.push new eventClass(event)

    return events

  publishPendingCommits: ->

    pendingCommits = @commits.find { isPublished: false }, sort: ['version', 'asc']
    pendingCommits.forEach (commit) => @publisher.publishCommit commit

  _lookupClass: (identifier) ->
    namespace = @globalNamespace
    path = identifier.split '.'

    for segment in path
      namespace = namespace[segment]

    if not namespace?
      throw new Error CommitStore.ERRORS.EVENT_CLASS_LOOKUP_FAILED + "<#{identifier}>"

    return namespace
