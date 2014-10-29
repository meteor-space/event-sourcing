
globalNamespace = this

class Space.cqrs.CommitPublisher

  @toString: -> 'Space.cqrs.CommitPublisher'

  Dependencies:
    commits: 'Space.cqrs.CommitCollection'
    eventBus: 'Space.cqrs.EventBus'
    commandBus: 'Space.cqrs.CommandBus'

  constructor: -> @globalNamespace = globalNamespace

  publishCommit: (commit) =>

    for event in commit.changes.events
      event.version = commit.version
      eventClass = @_lookupClass event.type
      @eventBus.publish new eventClass(event)

    for command in commit.changes.commands
      commandClass = @_lookupClass command.type
      @commandBus.send commandClass, command

    @commits.update commit._id, $set: isPublished: true

  _lookupClass: (identifier) ->
    namespace = @globalNamespace
    path = identifier.split '.'

    for segment in path
      namespace = namespace[segment]

    if not namespace?
      throw new Error CommitStore.ERRORS.EVENT_CLASS_LOOKUP_FAILED + "<#{identifier}>"

    return namespace